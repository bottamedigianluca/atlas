*** Extracted Visual FoxPro Source Code from fedi_doc.vcx ***

*** CLASS / OBJECT: fedi (BaseClass: form, Parent: ) ***
*** PROPERTIES ***
Top = 3

Left = 0

Height = 503

Width = 652

DoCreate = .T.

Comment = "BDFA08F0-362D-4F98-891E-0CC316313105"

Caption = "Gestione Documenti"

WindowState = 0

modefromprelievo = 0

id_dotes = 0

preffromprelievo = (Null)

modefromarcagp = .F.

allowsaveandnew = .T.

Name = "fedi"

statusbar.BorderLine.Name = "BorderLine"

statusbar.TimerDate.Name = "TimerDate"

statusbar.TimerRepos.Name = "TimerRepos"

statusbar.Top = 481

statusbar.Left = 0

statusbar.Width = 652

statusbar.Height = 20

statusbar.TabIndex = 2

statusbar.Name = "statusbar"

timer4ExecAsync.Name = "timer4ExecAsync"

title_bar.BtnLabel.Name = "BtnLabel"

title_bar.lblLabel.Name = "lblLabel"

title_bar.Top = 26

title_bar.Width = 652

title_bar.TabIndex = 4

title_bar.caption = ('Titolo')

title_bar.Name = "title_bar"

SCMenu.Top = 1

SCMenu.Left = 149

SCMenu.Name = "SCMenu"

tbenabler.Top = 0

tbenabler.Left = 27

tbenabler.Name = "tbenabler"

imgRecInfo.Height = 16

imgRecInfo.Left = 185

imgRecInfo.Top = 4

imgRecInfo.Width = 16

imgRecInfo.Name = "imgRecInfo"

PF.ErasePage = .T.

PF.PageCount = 3

PF.pgElenco.PageOrder = 1

PF.pgElenco.Name = "pgElenco"

PF.pgGenerale.Caption = "Generale"

PF.pgGenerale.PageOrder = 2

PF.pgGenerale.Name = "pgGenerale"

PF.Pgbase3.Comment = "5AE9991D-FECC-42E2-BA63-1ED5A23B01C4"

PF.Pgbase3.Caption = "DMS"

PF.Pgbase3.PageOrder = 3

PF.Pgbase3.longcaption = DMS

PF.Pgbase3.Name = "pgAllegati"

PF.ActivePage = 1

PF.Top = 28

PF.Left = 0

PF.Width = 654

PF.Height = 455

PF.TabIndex = 1

PF.Name = "PF"


*** METHODS ***
PROCEDURE cmdrowcopy

LParameters lFromDetailForm



Local oControl, nMode, oRow, nWA



If lFromDetailForm

	oControl = ThisForm.PF.pgGenerale.PF.pgRighe.Cnt.Grid

Else

	If Type('ThisForm.ActiveControl') != 'O'

		Return

	EndIf

	oControl = ThisForm.ActiveControl

	If oControl.Class != 'Stdgrid'

		Wait Window 'Selezionare una Griglia'

		Return

	EndIf

EndIf



If Eof(oControl.RecordSource)

	Wait Window 'Nessuna riga da copiare'

	Return

EndIf



nWA = Select(0)

Select (oControl.RecordSource)

Scatter Name oRow Memo

Select (nWA)



oControl.AddProperty('oRow', oRow)







ENDPROC

PROCEDURE cmdrowpaste

LParameters lFromDetailForm



Local oControl, nMode, oRow, nWA

If lFromDetailForm

	oControl = ThisForm.PF.pgGenerale.PF.pgRighe.Cnt.Grid

Else

	If Type('ThisForm.ActiveControl') != 'O'

		Return

	EndIf

	oControl = ThisForm.ActiveControl

	If oControl.Class != 'Stdgrid'

		Wait Window 'Selezionare una Griglia'

		Return

	EndIf

EndIf



If Eof(oControl.RecordSource)

	Wait Window 'Nessuna riga di destinazione disponibile'

	Return

EndIf



If Vartype(oControl.oRow) != 'O'

	Wait Window "E' necessario selezionare una riga da copiare"

	Return

EndIf



nWA = Select(0)

Select (oControl.RecordSource)



** Copia sulla riga tutti i dati che non creano problemi

Gather Name oControl.oRow Memo Fields Except Riga, Id_DoRig, Id_DoRig_Evade, Id_DoDB



** Gestisco a parte il caso di Id_DoDB

If IsEmpty(Id_DoDB) And !IsEmpty(oControl.oRow.Id_DoDB)

	Thisform.DuplicateCustomDB(oControl.oRow.Id_DoDB, .T.)

EndIf



oControl.Refresh()

oControl.colcd_AR.StdText1.setvalue(oControl.oRow.Cd_AR)	&& (ocontrol.colcd_AR.StdText1.value)		&& check del BUG 4705



Select (nWA)





ENDPROC

PROCEDURE cmdrowadd

LParameters lFromDetailForm



Local oControl



If lFromDetailForm

	oControl = Thisform.PF.pgGenerale.PF.pgRighe.cnt.Grid

Else

	If Type('ThisForm.ActiveControl') != 'O'

		Return

	EndIf

	oControl = ThisForm.ActiveControl

	If !oControl.IsA('Stdgrid')

		Wait Window 'Selezionare una Griglia'

		Return

	EndIf

EndIf



If oControl.AllowAddNew

	oControl.RowAppend()

EndIf



If lFromDetailForm

	oControl.Refresh()

EndIf

ENDPROC

PROCEDURE cmdrowdel

LParameters lFromDetailForm



Local oControl, oFocusCtrl, cGridWA



** SEZIONE 1 --> Sezione Enter nei due casi



If lFromDetailForm

    oControl = Thisform.PF.pgGenerale.PF.pgRighe.cnt.Grid

    cGridWA      = Proper(oControl.RecordSource)

Else

    If Type('ThisForm.ActiveControl') != 'O'

           Return

    Endif

    oControl = Thisform.ActiveControl

    

    If !oControl.IsA('Stdgrid')

           Wait Window 'Selezionare una Griglia'

           Return

    Endif

    cGridWA      = Proper(oControl.RecordSource)





    If cGridWA == 'Dorig'

           ** Mi accerto che la cella della griglia che ha il fuoco abbia un dato corretto;  per fare questo

           ** sposto il fuoco altrove in modo che si scateni IsValid() per il controllo della griglia che ha

           ** il fuoco, il quale lo rilascia solo se va tutto bene; in questo modo testando il controllo che

           ** risulta attivo dopo il test posso sapere se la griglia lo ha rilasciato oppure no.



           ** BUG 812: il fuoco veniva spostato su txtCd_CF ma questo campo quando questa form viene lanciata

           ** dalla Cmd_DoPrelievo è disabilitato e non prende il fuoco,  non consentendo così l'eliminazione

           ** della riga della griglia che si vuole cancellare; allora è stato scelto txtDataDoc che è sempre

           ** abilitato

           

           ** GIANKY propone: si potrebbe migliorare tutto (forse) prelevando il controllo attivo sulla griglia

           ** attraverso GetActiveControl, forzando poi un lRet = oCtrl.SetValue(oCtrl.Value) e valutando lRet,

           ** che coincide con il valore ritornato dalla IsValid(),   e quindi decidere se continuare oppure no 

           ** in base al valore di lRet

           

           Thisform.PF.pgGenerale.txtDataDoc.Field.SetFocus()

           oFocusCtrl = Thisform.ActiveControl 

           If oFocusCtrl.Class = 'Stdgrid'

                 oControl.OnFocus(.T.)

                 Return

           Else

                 oControl.SetFocus()

           EndIf

    EndIf

    

EndIf



** SEZIONE 2 --> Sezione Delete comune



oControl.RowDelete()



** SEZIONE 3 --> Sezione Leave nei due casi



If lFromDetailForm

    If !Bof(cGridWA)

           Skip -1 In (cGridWA)

    Else

           If !Eof(cGridWA)

                 Skip +1 In (cGridWA)

           EndIf

    EndIf

    If Thisform.DE.&cGridWA..RecCountND() = 0

           Thisform.CmdRowAdd(.T.)

    EndIf

    oControl.Refresh()

EndIf



ENDPROC

PROCEDURE cmdrowins

LParameters lFromDetailForm



Local oControl



If lFromDetailForm

	oControl = Thisform.PF.pgGenerale.PF.pgRighe.cnt.Grid

Else

	If Type('ThisForm.ActiveControl') != 'O'

		Return

	EndIf

	oControl = ThisForm.ActiveControl

	If !oControl.IsA('Stdgrid')

		Wait Window 'Selezionare una Griglia'

		Return

	EndIf

EndIf



If oControl.AllowAddNew

	oControl.RowInsert()

EndIf



If lFromDetailForm

	oControl.Refresh()

EndIf





ENDPROC

PROCEDURE cmdrowdown

LOCAL oControl



IF TYPE('ThisForm.ActiveControl') != 'O'

	RETURN

ENDIF

	

oControl = ThisForm.ActiveControl

IF oControl.Class != 'Stdgrid'

	WAIT WINDOW 'Selezionare una Griglia'

	RETURN

ENDIF



oControl.RowForward()

ENDPROC

PROCEDURE cmdrowup

LOCAL oControl



IF TYPE('ThisForm.ActiveControl') != 'O'

	RETURN

ENDIF

	

oControl = ThisForm.ActiveControl

IF oControl.Class != 'Stdgrid'

	WAIT WINDOW 'Selezionare una Griglia'

	RETURN

ENDIF



oControl.RowBackward()

ENDPROC

PROCEDURE setpicturevaluta

Local cPicSep, cPicSepPrzUn, cVLAlias



With Thisform.PF.pgGenerale



	cVLAlias = .txtCd_VL.Field.FKAlias

	If Empty(cVLAlias)

		.txtCd_VL.Field.Refresh()

		cVLAlias = .txtCd_VL.Field.FKAlias

	Endif



	cPicSep		 = Eval(cVLAlias + '.PicSep'     )

	cPicSepPrzUn = Eval(cVLAlias + '.PicSepPrzUn')



	With .PF.pgRighe

		If .ControlCount > 0

			.Cnt.Grid.ColPrezzoUnitarioV		 .InputMask = cPicSepPrzUn

			.Cnt.Grid.ColPrezzoUnitarioV.Text1.InputMask = cPicSepPrzUn

			.Cnt.Grid.ColPrezzoTotaleV			 .InputMask = cPicSep

			.Cnt.Grid.ColPrezzoTotaleV.Text1	 .InputMask = cPicSep

		Endif

	Endwith



	With .PF.pgPiede

		If .ControlCount > 0

			.Cnt.cntFattura.Grid.ColImportoV				.InputMask = cPicSep

			.Cnt.cntFattura.Grid.ColImportoEvadibileV	.InputMask = cPicSep

			.Cnt.cntFattura.Grid.ColImportoEvasoV		.InputMask = cPicSep

			.Cnt.cntFattura.txtAcconto.Field1			.InputMask = cPicSep

			.Cnt.cntFattura.txtAbbuono.Field				.InputMask = cPicSep

		Endif

	Endwith



Endwith



ENDPROC

PROCEDURE rinumerarighe

LParameters cAlias

Local nRec, nOldWA, nCount, nMax

Local Array aRighe[1]

nOldWA = Select(0)

nMax = ThisForm.DE.&cAlias..RecCountND()



If nMax > 0

	Select (cAlias)

	nRec = RecNo()

	Dimension aRighe(nMax)

	Set Order To Riga

	Go Top

	For nCount = 1 To nMax

		aRighe[nCount] = RecNo()

		Skip

	EndFor

	Set Order To 0

	For nCount = 1 To nMax

		Go (aRighe[nCount])

		If (Riga != nCount)

			Replace Riga With nCount

		EndIf

	EndFor

	Set Order To Riga	

	Locate Record nRec

	Select (nOldWA)

EndIf



ENDPROC

PROCEDURE cmdpreleva

LPARAMETERS lQuerySupported



Local oFormPrel, oParmPrel, cIdDoTesExcl, cIdDoRigExcl, cIdDoRigSpesaExcl



IF lQuerySupported

	LOCAL oRec

	oRec = xSqlExec2OBJ("SELECT COUNT(*) AS NumPrelevabili FROM DoDoPrel WHERE Cd_DO = " + Format4SPT(DoTes.Cd_DO))

	RETURN (oRec.NumPrelevabili > 0) AND (This.Mode != FEDIMODE_SHOW) AND EMPTY(THIS.ModeFromPrelievo)

ENDIF



WITH THIS.PF.pgGenerale

	IF IsEmpty(.txtCd_DO.FIELD.VALUE)

		xMessageBox(Thisform.TB_(,'E73407D5-8703-4CA1-A2D0-6B2F9194D577', 'Specificare il documento da creare!!'), 16 )

		RETURN

	ENDIF

	IF IsEmpty(SUBSTR(.txtCd_CF.FIELD.VALUE, 2))

		xMessageBox(Thisform.TB_(,'16CF4659-19B8-41AC-8A3F-F7BCC2767F5E', 'Specificare il %1! !!', .txtCd_CF.LABEL.CAPTION), 16 )

		RETURN

	ENDIF

ENDWITH



This.PrelBuildListExclude(@cIdDoTesExcl, @cIdDoRigExcl, @cIdDoRigSpesaExcl)



Local oRecTes

Select DoTes

Scatter Memo Name oRecTes

	

oParmPrel = CreateObject('Empty')

AddProperty(oParmPrel, 'Key'					 , 'Prelevamento Manuale'						 )

AddProperty(oParmPrel, 'cIdDoTesExcl'		 , cIdDoTesExcl									 )

AddProperty(oParmPrel, 'cIdDoRigExcl'		 , cIdDoRigExcl									 )

AddProperty(oParmPrel, 'cIdDoRigSpesaExcl' , cIdDoRigSpesaExcl								 )

AddProperty(oParmPrel, 'Cd_VL'				 , This.PF.pgGenerale.txtCd_VL.Field.Value )

AddProperty(oParmPrel, 'Cd_DO'				 , This.PF.pgGenerale.txtCd_DO.Field.Value )

AddProperty(oParmPrel, 'Cd_CF'				 , This.PF.pgGenerale.txtCd_CF.Field.Value )

AddProperty(oParmPrel, 'Cd_CF_AnagraficheObsolete', This.PF.pgGenerale.txtCd_CF.Field.AnagraficheObsolete)

AddProperty(oParmPrel, 'DataDoc'			 	 , This.PF.pgGenerale.txtDataDoc.Field.Value)

AddProperty(oParmPrel, 'FKMode'				 , This.PF.pgGenerale.txtCd_CF.Field.FKMode)

AddProperty(oParmPrel, 'oRecTes'				 , oRecTes											 )

AddProperty(oParmPrel, 'UIRigaRifPreleva'	 , This.PF.pgGenerale.txtCd_DO.Field.Fkrecord.UIRigaRifPreleva)



oFormPrel = RunCmd('Cmd_DoPrelievoInterno', Thisform, oParmPrel)

oFormPrel.HideOnClose = .T.

oFormPrel.Show(1)



** N.B.: La form di prelievo chiamerà il metodo PrelLoadRighe sulla conferma.

**			E' questo il metodo che scriverà effettivamente le righe ad una ad una.

**			Chiamerà tutti i metodi PrelXXX()



IF oFormPrel.WasConfirmed

	WITH THIS.PF.pgGenerale.PF

		.pgRighe.Cnt.Grid.SaveRecordSource()

		GO TOP IN DoRig

		.ActivePage = 2

		.pgRighe.Cnt.Grid.RestoreRecordSource()

		.pgRighe.Cnt.Grid.SetFocus()

	ENDWITH	

ENDIF



oFormPrel.Release()



ENDPROC

PROCEDURE prelbuildlistexclude

LPARAMETERS cIdDoTes, cIdDoRig, cIdDoRigSpesa



**	cIdDoTes, cIdDoRig e cIdDoRigSpesa BYREF

**

** Il seguente metodo verrà chiamato dalla form di prelevamento (manuale)

** per ottenere l'elenco di eventuali teste, righe e righeSpesa da escludere dal prelevamento.

**

** I tre parametri sono passati appositamente BYREF e deve essere riempiti con i riespettivi

** elenchi di Id: 

**		Id_DoTes 		per cIdDoTes 

**		Id_DoRig 		per cIdDoRig

**		Id_DoRigSpesa 	per cIdDoRigSpesa

**

** Entrambi gli elenchi sono separati da virgola e possono essere anche vuoti.

** Alcuni esempio validi: "152", "", "12,856,45"



** Codice per le righe spesa ancora da implementare

** N.B.: questo metodo viene chiamato dalla form di Prelievo Cmd_DoPrelievo



cIdDoTes			= IIF(DoTes.Id_DoTes != 0, TRAN(DoTes.Id_DoTes), '')



LOCAL i

cIdDoRig 		= ''

SELECT DoRig

COPY TO ARRAY aIdDoRig FIELDS Id_DoRig_Evade FOR !IsEMPTY(Id_DoRig_Evade) And (DoRig.Qta != Nvl(Oldval('Qta', 'DoRig'), 0) Or DoRig.QtaEvasa != Nvl(Oldval('QtaEvasa', 'DoRig'), 0))

FOR i = 1 TO _TALLY

	cIdDoRig = ',' + TRAN(aIdDoRig[i]) + cIdDoRig

NEXT

cIdDoRig = SUBSTR(cIdDoRig, 2)



cIdDoRigSpesa 	= ''

SELECT DoRigSpesa

COPY TO ARRAY aIdDoRig FIELDS Id_DoRigSpesa_Evade FOR !IsEMPTY(Id_DoRigSpesa_Evade) And (DoRigSpesa.ImportoV != Nvl(Oldval('ImportoV', 'DoRigSpesa'), 0) Or DoRigSpesa.ImportoEvasoV != Nvl(Oldval('ImportoEvasoV', 'DoRigSpesa'), 0))

FOR i = 1 TO _TALLY

	cIdDoRigSpesa = ',' + TRAN(aIdDoRig[i]) + cIdDoRigSpesa

NEXT

cIdDoRigSpesa = SUBSTR(cIdDoRigSpesa, 2)

RELEASE aIdDoRig 	&& Se lo dichiarassi local non si autodimensionerebbe









ENDPROC

PROCEDURE prelloadrighe

LParameters cDoTesDbfFileName, cDoRigDbfFileName, cDoRigSpesaDbfFileName, cDoRigPackListDbfFileName



** Callback chiamata dalla form di prelievo

** Riceve i nomi dei file DBF il cui tracciato sarà:

**

**	a) Per cDoTesDbfFileName quello di DoTes

**    più una colonna Selected L sempre a .T.

**

**	b) Per cDoRigDbfFileName quello di DoRig

**    più le seguenti colonne:

**			Selected				L		sempre (.T.)

**			Cd_ARMisuraPrel	C

**			FattoreToUM1Prel	N

**

** c) Per cDoRigSpesaDbfFileName quello di DoRigSpesa

**    più una colonna Selected L sempre a .T.

**

** Detti DBF vengono aperti da questo metodo ed alla fine devono venir chiusi.

** All'eliminazione dei files fisici ci penserà il chiamante (Form di prelievo)



** I files possono essere aperto in modo esclusivo e manipolati (modifiche, aggiunta records,

** eliminazione records, etc.) anche nella struttura (alter table) senza problemi.

**

** I tre DBF sono già ordinati fisicamente nel seguente modo

** DoTes 		: DataDoc

** DoRig 		: DataDoc, Riga

** DoRigSpesa 	: DataDoc, Riga



Local oRigheGrid, nDoRigrecNo

Local lPropDataOra, lPropDataConsegna

Local cTipoDoc,cCd_MGCausale, cDoAlias



** oDO = xSQLExec2Obj("SELECT * FROM DO WHERE Cd_DO = '" + THISFORM.PF.pgGenerale.txtCd_DO.FIELD.Value + "'")

cDoAlias		= ThisForm.PF.pgGenerale.txtCd_DO.Field.FkAlias

oRigheGrid	= ThisForm.PF.pgGenerale.PF.pgRighe.Cnt.Grid



** Controllo per ora il fatto che venga passato il nome di una tavola

** per determinare se devo caricarmi anche la testa!

If !Empty (cDoTesDbfFileName)

	Select DoTes

	Local oTesta

	Use (cDoTesDbfFileName) In 0 Alias DoTesPrel Exclu

	Select DoTesPrel

	Scatter Name oTesta Memo

	Select DoTes

	Append Blank



	lPropDataOra		= &cDoAlias..UIPropDataOra

	lPropDataConsegna = &cDoAlias..UIPropDataConsegna

	cTipoDoc	 	 		= &cDoAlias..TipoDocumento

	cCd_MGCausale		= &cDoAlias..Cd_MGCausale



	With oTesta



	.NumeroDoc			= ''

	.Id_DoTes			= 0

	.DataConsegna 		= Iif(lPropDataConsegna, 					 Datetime(), {})

	.TrasportoDataOra = Iif(cTipoDoc $ 'AB' And lPropDataOra, Datetime(), {})

	.Vettore1DataOra	= Iif(cTipoDoc $ 'AB' And lPropDataOra, Datetime(), {})

	.Vettore2DataOra	= Iif(cTipoDoc $ 'AB' And lPropDataOra, Datetime(), {})

	.Cd_DOVettore_1	= Iif(cTipoDoc $ 'FN', Null, .Cd_DOVettore_1)

	.Cd_DOVettore_2	= Iif(cTipoDoc $ 'FN', Null, .Cd_DOVettore_2)

	.Cd_MGCausale		= Null



	EndWith

	

	If Used(cDoAlias)	

		AddProperty(oTesta, 'DIEnabled', 	&cDoAlias..DIEnabled)

		AddProperty(oTesta, 'DIExecutive', 	&cDoAlias..DIExecutive)

		AddProperty(oTesta, 'DISave', 		&cDoAlias..DISave)

	endif



	Gather Name oTesta Memo

	Use In DoTesPrel

	

	If !Empty(oTesta.Cd_CF)

		** Sono costretto a fare così xché si tratta di un flag di interfaccia senza bound

		** Chiamare il .SetValue o direttamente l'OnValueChange del codice cliente scatenerebbe troppi eventi

		This.PF.pgGenerale.PF.pgPiede.Cnt.CntFattura.chkSpeseBolli.SetValue(Thisform.GetSpeseBolliFlag())

	EndIf

	

	If !Empty(oTesta.Cd_VL)

		** Anche qui sono costretto a fare così perché se chiamassi l'OnValueChange farebbe troppe cose...

		Local oVLRec

		This.PF.pgGenerale.txtCd_VL.Field.Refresh()

		oVLRec = This.PF.pgGenerale.txtCd_VL.Field.FKRecord

		Replace Decimali      With oVLRec.Decimali      In DoTes

		Replace DecimaliPrzUn With oVLRec.DecimaliPrzUn In DoTes

	EndIf

	

EndIf



Use (cDoRigDbfFileName) In 0 Alias DoRigPrel Exclu



** Ubicazioni

Replace																						;

	Cd_MGUbicazione_A	With Iif(IsNull(Cd_MG_A), Null, Cd_MGUbicazione_A)	;

	Cd_MGUbicazione_P	With Iif(IsNull(Cd_MG_P), Null, Cd_MGUbicazione_P)	;

All In DoRigPrel	

	

** Matricole

If !Evaluate(cDoAlias + '.mtrEnabled')

	Replace Matricole With Null For !IsEmpty(Matricole) In DoRigPrel

EndIf



Select DoRig

nDoRigrecNo = RecNo()

Append From (cDoRigDbfFileName)

Use In DoRigPrel

Replace All FattoreTOUM1_Prelevato With FattoreTOUM1 In	DoRig

Select DoRig

Locate Record nDoRigrecNo



Use (cDoRigSpesaDbfFileName) 	In 0 Alias DoRigSpesaPrel 	Exclu



Select DoRigSpesa

nDoRigrecNo = RecNo()

Append From (cDoRigSpesaDbfFileName)



If ThisForm.ModeFromprelievo = 1



	ThisForm.CalcSpese(0x01)



	** Dalla form Cmd_DoPrelivoCreazione non viene richiamato alcun evento della fedi_doc che va ad impostare il button per cui rimane sempre disabilitato.

	Thisform.Toolbar.Buttons('FTEXML').Enabled = Thisform.Fte_Isxml()

	

EndIf



RecSignTest(ThisForm.PF.pgGenerale.PF.pgPiede.Cnt.cntFattura.Grid, ThisForm.DE.DoTes) && nota: blocco requery



Locate Record nDoRigrecNo



Use In DoRigSpesaPrel



If Vartype(cDoRigPackListDbfFileName) = 'C' And Evaluate(cDoAlias + '.PkLstEnabled')

	Use (cDoRigPackListDbfFileName) 	In 0 Alias DoRigPackListPrel 	Exclu

	Select DoRigPackList

	Append From (cDoRigPackListDbfFileName)

	ThisForm.DE.DoRigPackList.RunCmd('SET FILTER TO')

	Scan

		Select DoRig

		Locate For Id_DoRig = DoRigPackList.Id_DoRig

		Select DoRigPackList

		Replace Id_DoRig With RecNo('DoRig')

	EndScan

	Replace All Id_DoRigPackList With 0

	ThisForm.DE.DoRigPackList.RunCmd('SET FILTER TO Id_DoRig = xDefault(DoRig.Id_DoRig, RECNO("DoRig"))')

	Use In DoRigPackListPrel

EndIf



Select DoRig

Replace Id_DoRig With RecNo() For Id_DOTes != DOTes.id_dotes



RecSignTest(oRigheGrid, ThisForm.DE.DoTes) && nota: blocco requery

RecSignTest(ThisForm, 	ThisForm.DE.DoTes) && nota: blocco requery dettaglio riga



** In VFP8 non si può fare Refresh() perchè se la griglia non è visibile il Refresh viene ignorato

ThisForm.PF.pgGenerale.PF.pgPiede.Cnt.cntFattura.Grid.SaveRecordSource()

ThisForm.PF.pgGenerale.PF.pgPiede.Cnt.cntFattura.Grid.RestoRerecordSource()



** Imposto la prop che identifica se sono abilitate le dichiarazioni e gestisco UI delle colonne DI

Thisform.DoIntento_Visible(.T.)



If (!&cDoAlias..DISave Or Bitand(Thisform.Mode, FEDIMODE_INS_DUP) = 0)



	Thisform.Log_Start('DOINTENTO_APPLY@FEDI_DOC.PRELLOADRIGHE')



	** Ripulisco i dati perché la dichiarazione viene sempre applicata dalla prima riga per valutare il caso in cui sia cambiata la situazione in condizioni limite

	Thisform.DoIntento_Clear()



	** Applico dichiarazioni intento

	Thisform.DoIntento_Apply()



	Thisform.Log_End()



EndIf



ENDPROC

PROCEDURE prelgetfirstrownumber

LPARAMETERS lRigheSpesa

LOCAL nRecNo, nMax

SELECT DoRig

IF lRigheSpesa

	SELECT DoRigSpesa

ENDIF

nRecNo = RECNO()

CALCULATE MAX(Riga) TO nMax 

LOCATE RECORD nRecNo

RETURN nMax+1

ENDPROC

PROCEDURE cmdstop_pa_edit

LOCAL oFormOption



oFormOption = NewObjectWCR0('pa_options', 'cmd_doprelievo')



oFOrmOption.TOP	= THIS.TOP + 10

oFOrmOption.LEFT	= THIS.LEFT + 10



oFOrmOption.opgAzione.VALUE = MAX(THIS.PARAMETERS.ParentForm.PA_Options, 1)

oFOrmOption.HideOnClose = .T.

oFOrmOption.SHOW(1)

THIS.PARAMETERS.ParentForm.PA_Options = oFOrmOption.opgAzione.VALUE

oFOrmOption.Release()



ENDPROC

PROCEDURE linkondemand

** Questo metodo viene richiamato soltanto in UPD dal DE



Local oPref, oCF, cReserved, cText, lCoge

Local lGen, lExist



With ThisForm



** Nel caso sia richiesta la conferma da parte dell'utente per la rigenerazione testo il byte riservato in DoTes, DoRig, DoRigSpesa

** ed eventualmente lo setto a '0' (Nothing To Do)



oPref = xSqlExec2Obj("Select DOLinkRicrea, DoScRicrea, DoIntraRicrea From Preferenza")

oCf	= ThisForm.PF.pgGenerale.txtCd_CF.Field.FKRecord



** DoTes.TipoFattura != 0 -> Finché non verrà implementata la possibilità di mantenere il

** protocollo per i movimenti contabili collegati in caso di compensazioni



If oApp.LicInfo.CG_Main And DOTes.Contabile



	lCoge = xSQLExec2Bit(Textmerge('Exists(Select * From CGMovT Where Id_Dotes = <<DoTes.Id_DoTes>>)'))



	** Se non esiste il COGE lo rigenero anche se non è stato modificato nulla chiedendo all'utente l'eventuale conferma in base alle preferenze.

	If !lCoge

		xSqlExec("UPDATE DoTes      SET Reserved_1 = STUFF(Reserved_1, 2, 1, 'I') WHERE Id_DoTes = " + Tran(DoTes.Id_DoTes) + Chr(13) + ;

					"UPDATE DoRig      SET Reserved_1 = STUFF(Reserved_1, 2, 1, 'I') WHERE Id_DoTes = " + Tran(DoTes.Id_DoTes) + Chr(13) + ;

					"UPDATE DoRigSpesa SET Reserved_1 = STUFF(Reserved_1, 2, 1, 'I') WHERE Id_DoTes = " + Tran(DoTes.Id_DoTes))



		cText = Thisform.TB_(,'78D23E35-C37D-4582-8FD6-4F827179FC20', ;

									"ATTENZIONE! Non è stato rilevato il movimento contabile, si consiglia di rigenerarlo." + Chr(13) + Chr(13) + ;

									"Proseguo con la generazione?")



	EndIf



	cReserved = xSqlExec2Var(Textmerge("Select Reserved = dbo.afn_GetReservedStatus_DO_Contabilizza(<<DoTes.Id_DoTes>>)"))

	

	If oPref.DOLinkRicrea Or (DoTes.TipoFattura != 0 And DoTes.Clifor == 'F')



		** Movimento contabile

		If cReserved == 'R'

		

			If DoTes.TipoFattura != 0 And DoTes.CliFor = 'F'

				Text To cText NoShow Pretext 1+2

					ATTENZIONE! È stato modificato un campo chiave per la generazione del movimento contabile.

					Verrà di conseguenza rigenerata anche la registrazione contabile di compensazione.

					Tale procedura implica la riassegnazione del primo numero di protocollo libero:

					si consiglia a tal proposito di controllarne la correttezza nel relativo movimento contabile

					ed eventualmente agire manualmente per correggerlo. In caso si scegliesse di non rigenerare

					il movimento di fattura, la scrittura di compensazione manterrà il numero di protocollo

					originario, ma sarà necessario modificarne manualmente il contenuto, al fine di renderlo 

					congruente con i dati del documento aggiornato.

					

					Proseguo con la generazione?

				EndText

				cText = Thisform.TB_(,'B9F025AD-456D-4C97-8303-4A1555A322D4', cText)

			Else

				

				cText = Thisform.TB_(,'C20E8B46-B659-49AF-ABD5-DBF635543460', ;

											"ATTENZIONE! E' stato modificato un campo chiave per la generazione del movimento contabile." + Chr(13) + Chr(13) + ;

											"Proseguo con la generazione?")



			EndIf 

			

		EndIf

		

		If !Empty(cText) And xMessageBox(cText, MB_ICONQUESTION + MB_YESNO) = IDNO



			xSqlExec("UPDATE DoTes      SET Reserved_1 = STUFF(Reserved_1, 2, 1, '0') WHERE Id_DoTes = " + Tran(DoTes.Id_DoTes) + Chr(13) + ;

						"UPDATE DoRig      SET Reserved_1 = STUFF(Reserved_1, 2, 1, '0') WHERE Id_DoTes = " + Tran(DoTes.Id_DoTes) + Chr(13) + ;

						"UPDATE DoRigSpesa SET Reserved_1 = STUFF(Reserved_1, 2, 1, '0') WHERE Id_DoTes = " + Tran(DoTes.Id_DoTes))



		EndIf

	

	EndIf

	

EndIf



** Scadenze

IF !oApp.LicInfo.CG_Main And oPref.DOScRicrea



	cReserved = xSqlExec2Var(Textmerge("Select Reserved = dbo.afn_GetReservedStatus_DO_SC(<<DoTes.Id_DoTes>>)"))



	IF cReserved == 'R' And ;

		xSQLExists('SC', "Id_Dotes = " + TRAN(DOTes.Id_DoTes)) And ;

		xMessageBox(Thisform.TB_(,'B50C524A-8105-40B0-B5C6-4D5F46C551F5', "ATTENZIONE! E' stato modificato un campo chiave per la generazione delle scadenze." + CRLF + ;

																					"Proseguo con la generazione?"), MB_ICONQUESTION + MB_YESNO) = IDNO



		xSQLExec("UPDATE DOTes 		 SET Reserved_1 = STUFF(Reserved_1, 4, 1, '0') WHERE Id_DOtes = " + Tran(DoTes.Id_DoTes) + Chr(13) + ;

					"UPDATE DoRig      SET Reserved_1 = STUFF(Reserved_1, 4, 1, '0') WHERE Id_DoTes = " + Tran(DoTes.Id_DoTes) + Chr(13) + ;

					"UPDATE DoRigSpesa SET Reserved_1 = STUFF(Reserved_1, 4, 1, '0') WHERE Id_DoTes = " + Tran(DoTes.Id_DoTes))



	ENDIF

ENDIF



** <<-------------------- Intra Section Start --------------------->>

** La gestione è leggermente diversa dagli altri stati del reserved in quanto per gli intra non esiste una asp_INTRA_COM che verifica i campi chiave modificati.



If oApp.LicInfo.CG_Main And InList(DoTes.TipoDocumento, 'F', 'A', 'N') And (DOTes.UE Or (DOTes.UE != Nvl(This.De.DoTes.Old.UE, .F.)))



	lGen			= .T.																				&& Per default rigenero sempre, l'utente può eventualmente non farlo

	lExist		= xSQLExists('Intra', 'Id_Dotes = ' + TRAN(Dotes.ID_Dotes)) 	&& Verifico la presenza di movimenti intra associati al documento

	cReserved 	= xSqlExec2Var(Textmerge("Select dbo.afn_GetReservedStatus_DO_Intra(<<DoTes.Id_DoTes>>)"))



	Do Case

	

		** In caso il documento non sia + UE avverto l'utente che gli intra verranno eliminati, ma ci deve pensare la asp_DO_End/asp_Intra_DO

		Case lExist And (This.De.DoTes.Old.Ue And !DoTes.Ue)



			xMessageBox(Thisform.TB_(,'6E79E288-FDE2-415C-9206-63D81A7EE1C2', 'Sono state rilevate movimentazioni intrastat che verranno eliminate in quanto il documento non presenta più i requisiti necessari per gestirle.'))



		Case !oCf.Intra

		

			lGen = .F.			



		Case oPref.DoIntraRicrea And cReserved == 'R' And DoTes.Ue And lExist And ;

			xMessageBox(Thisform.TB_(,'B701F7EB-AF55-4A7B-A2F1-596C66A1AAAC', 'Sono state rilevate movimentazioni intrastat collegate al documento.' + Chr(13) + 'Vuoi eliminarle ed elaborarle nuovamente?'), MB_YESNO + MB_ICONQUESTION + MB_DEFBUTTON2) = IDNO

	

			lGen = .F.

	

		Case oPref.DoIntraRicrea And cReserved == 'R' And DoTes.Ue And !lExist And ;

			xMessageBox(Thisform.TB_(,'31E8F2CA-EE12-4CCC-9B3B-EE8E60735DF4', 'Non è stata rilevata alcuna elaborazione intra per il documento.' + Chr(13) + 'Vuoi generarla ora?'), MB_YESNO + MB_ICONQUESTION + MB_DEFBUTTON2) = IDNO



			lGen = .F.

		

	Endcase

		

	** Resetto il byte di stato per non rigenerare 

	Iif(!lGen, xSQLExec("Update DOTes Set Reserved_1 = STUFF(Reserved_1, 9, 1, 'X') WHERE Id_DOtes = " + Tran(DoTes.Id_DoTes)), .T.)



EndIf



** <<-------------------- Intra Section End --------------------->>

	

EndWith





ENDPROC

PROCEDURE linkmanager

LOCAL oPref, oForm

LOCAL cStmt, nWA, lBlackList



WITH ThisForm



nWA	= SELECT(0)

oPref = xSqlExec2Obj("SELECT * FROM Preferenza")

 

** Modifico alcune delle preferenze in base a quanto richiesto dal wizard di emissione

If !IsEmpty(ThisForm.ModeFromPrelievo) And !IsNull(ThisForm.PrefFromPrelievo)

	oPref.DOlinkUIModifica	= ThisForm.PrefFromPrelievo.DOlinkUIModifica

	oPref.DOScUIModifica		= ThisForm.PrefFromPrelievo.DOScUIModifica

	oPref.DOIntraUIModifica	= ThisForm.PrefFromPrelievo.DOIntraUIModifica

EndIf

 

This.Addproperty('nId_CGMovT', xSQLExec2Var('SELECT Id_CGMovT FROM CGMovT WHERE Id_DoTes = ' + TRAN(DoTes.Id_DoTes)))

 

**********************************************************************

** Movimento contabile

**********************************************************************



** Nel caso venga richiesta la visualizzazione e ci sia l'ID di link al movimento contabile.

IF oApp.LicInfo.CG_Main And !IsEmpty(This.nID_CGMovT)

 

	** Mi serve per sapere se è una NC ad un C/F in blacklist.

	** Nel caso viene mostrata sempre la modalità interattiva in edit per il COGE

	Text To cStmt Textmerge Noshow Pretext 2

		Exists (

		Select * From           CF

		Inner Join RaAnagrafe	RA On CF.Cd_CF = RA.Cd_CF

		Inner Join AE_Paese		AE On RA.Cd_AE_Paese  = AE.Cd_AE_Paese And AE.Blacklist = 1

		Where CF.Cd_CF = '<<DoTes.Cd_CF_Fatt_R>>')

	EndText

	 

	lBlackList = (DoTes.TipoDocumento == 'N') And xSQLExec2Bit(cStmt)

 

	If oPref.DOLinkUIModifica Or lBlackList



		ThisForm.ProgBarAdvance(Thisform.ProgressBar.Value + 1, ThisForm.GetDynamicMessage(-1) + ' [Visione movimento contabile]')

		oForm = RunFedi('Fedi_CGMovT', ThisForm, 'CgMovT.Id_CGMovT = ' + TRAN(This.nID_CgMovT), , 3, This.nID_CgMovT)



		IF Vartype(oForm) == 'O' 



			oForm.Top  = This.Top  + 20

			oForm.Left = This.Left + 20



			oForm.CmdPgGenerale()



			** Se voglio eseguire la form in edit mode ...

			If oPref.DOLinkStartMode = 2 Or lBlackList

				oForm.ExitAfterEdit = .T.

				oForm.CmdEdit()

				Iif(lBlackList, oForm.pf.pggenerale.pf.pggenerale.txtperiodorif.SetFocus(), .T.)

			Endif



			oForm.Show(1)



		EndIf

 

	EndIf



EndIf

 

** -------------------------------------------------------------------

** Visualizzazione scadenze

** -------------------------------------------------------------------

Iif(oPref.DOScUIModifica, .LinkSC(), .T.)

 

** -------------------------------------------------------------------

** Visualizzazione intra

** -------------------------------------------------------------------

Iif(oPref.DOIntraUIModifica And oApp.LicInfo.CG_Main, .LinkIntra(), .T.)

 

EndWith



SELECT (nWA)



ENDPROC

PROCEDURE printdocument

LParameters nId_DoTes, nAction, cUd_ReportDoc



Local Array aPrintInfo[1]		&& Array di oggetti passati all'engine di stampa (modulo, copie, device, etc..)

Local oRepDocEng, oRepParm		&& Oggetto Engine di stampa documenti, Oggetto Parametri di stampa documenti

Local nCount, lCloseDOReport

Local lComMgrDebug

lComMgrDebug 		= ( xGetEnv("COMmgr_Debug"		) = "1" )



nCount = 0



If !Used('DOReport')

	lCloseDOReport = .T.

	xSqlExec("SELECT * FROM DOReport WHERE Cd_DO = " + Format4Spt(DoTes.Cd_DO) + ;

		" AND (ComputerName IS NULL OR ComputerName =" + Format4Spt(oApp.ComputerName) + ") ORDER BY Riga", "DOReport")

Else

	lCloseDOReport = .F.

	Select DOReport

EndIf



** Abbiamo 2 casi:

** se passo cUd_ReportDoc "elaboro" una copia per il report passato, altrimenti se si tratta di una

** anteprima uso il report corrente (oppure il primo della lista) invece se si tratta di una stampa

** passo in rassegna tutti i report e ciascuno per il suo numero di copie

If lComMgrDebug	&& TODO -> rimuovere in futuro

   OutputDebugString(Textmerge("[Fedi->PrintDocument]Report <<cUd_ReportDoc>>; Action <<nAction>>"))

EndIf



If !Empty(cUd_ReportDoc)



******************************************************************************************************************************

	Local cPrinterName, cAlias, cSpecialOutput, cHtmlContent



	If lComMgrDebug	&& TODO -> rimuovere in futuro

	   OutputDebugString(Textmerge("[Fedi->PrintDocument]Ho cUd_ReportDoc <<cUd_ReportDoc>>"))

	EndIf



	cAlias = 'DOReport'

	cSpecialOutput = ''

	cHtmlContent	= ''

	

	Do Case

		Case nAction = RE_ACT_PRINT_TO_EMAIL



			If DOReport.Device = GetPrnMailerName()



				** Se il modulo è già configurato per essere inviato via Mail, allora mostro direttamente la form di invio, e non la form di configurazione mail

				cPrinterName 	= RTrim(DOReport.Device)

				cSpecialOutput = DOReport.SpecialOutput

				cHtmlContent	= DoReport.HtmlContent

			

			Else

				** Pet tutti gli altri modulo, mostro la configurazione della mail

				cPrinterName = GetPrnMailerName()

				

				Local oConfForm

				oConfForm = NewObject0('OutConfForm', 'Libs\SysForm')

				oConfForm.AcceptLocalPath  = .T.

				oConfForm.AcceptGlobalPath = .T.

				** oConfForm.Cnt.chkSendAlways.Value = .T.

				oConfForm.SetStatus(&cAlias..SpecialOutput)

	**				If !IsEmpty(&cAlias..HtmlContent)

	**					oConfForm.SetHtmlContent(&cAlias..HtmlContent)

	**				EndIf 

				oConfForm.HideOnClose = .T.

				oConfForm.Show(1)

				If oConfForm.WasConfirmed

					cSpecialOutput = oConfForm.GetStatus()

	**					cHtmlContent   = FileToStr(oConfForm.GetHtmlContent())

				EndIf

				oConfForm.Release()

			EndIf 



		Case nAction = RE_ACT_PRINT_TO_FILE_PDF

			cPrinterName = PRN_PDF_PRINTERNAME



		Case nAction = RE_ACT_PRINT_TO_FILE_RTF

			cPrinterName = PRN_RTF_PRINTERNAME



		Case nAction = RE_ACT_PRINT_TO_FILE_HTM

			cPrinterName = PRN_HTM_PRINTERNAME



		Case nAction = RE_ACT_PRINT_TO_FILE_XLS

			cPrinterName = PRN_XLS_PRINTERNAME



		Case nAction = RE_ACT_PRINT_TO_FILE_TXT

			cPrinterName = PRN_TXT_PRINTERNAME



		Case nAction = RE_ACT_PRINT_TO_FILE_BIN

			cPrinterName = PRN_BIN_PRINTERNAME

			

		Case nAction = RE_ACT_PRINT_TO_PASSPORT_FAX

			cPrinterName = PRN_FAX_PRINTERNAME

			** TODO! PASSPORT DEV -> è ancora da sistemare!

			

			Local oConfForm

			oConfForm = NewObject0('OutConfPassportForm', 'Libs\SysForm')

			oConfForm.SetStatus("This.SetAction("+Transform(nAction)+")")

			oConfForm.SetStatus(&cAlias..SpecialOutput)

			oConfForm.HideOnClose = .T.

			oConfForm.Show(1)

			If oConfForm.WasConfirmed

				cSpecialOutput = oConfForm.GetStatus()

			EndIf

			oConfForm.Release()

			

		Case nAction = RE_ACT_PRINT_TO_PASSPORT_LOL

			cPrinterName = PRN_LOL_PRINTERNAME

			** TODO! PASSPORT DEV -> è ancora da sistemare!

						

			Local oConfForm

			oConfForm = NewObject0('OutConfPassportForm', 'Libs\SysForm')

			oConfForm.SetStatus("This.SetAction("+Transform(nAction)+")")

			oConfForm.SetStatus(&cAlias..SpecialOutput)

			oConfForm.HideOnClose = .T.

			oConfForm.Show(1)

			If oConfForm.WasConfirmed

				cSpecialOutput = oConfForm.GetStatus()

			EndIf

			oConfForm.Release()

			

		Case nAction = RE_ACT_PRINT_TO_PASSPORT_ROL

			cPrinterName = PRN_ROL_PRINTERNAME

			** TODO! PASSPORT DEV -> è ancora da sistemare



			Local oConfForm

			oConfForm = NewObject0('OutConfPassportForm', 'Libs\SysForm')

			oConfForm.SetStatus("This.SetAction("+Transform(nAction)+")")

			oConfForm.SetStatus(&cAlias..SpecialOutput)

			oConfForm.HideOnClose = .T.

			oConfForm.Show(1)

			If oConfForm.WasConfirmed

				cSpecialOutput = oConfForm.GetStatus()

			EndIf

			oConfForm.Release()



		Otherwise

			cPrinterName = RTrim(DOReport.Device)



	EndCase



	nCount = 1

	aPrintInfo[1] = NewObjPrintInfo(cUd_ReportDoc, 1, cPrinterName, cSpecialOutput, cHtmlContent)



Else

	If lComMgrDebug	&& TODO -> rimuovere in futuro

	   OutputDebugString(Textmerge("[Fedi->PrintDocument]NON ho alcun cUd_ReportDoc"))

	EndIf





	This.PF.pgGenerale.PF.pgmoduli.Cnt.Grid.Refresh()	&&-->  Bug 961: mi assicuro che DOReport sia posizionato correttamente

	Do Case

		Case nAction = RE_ACT_PRINT_TO_SCREEN

			If Eof()

				Go Top

			EndIf

			If !Eof() And !Empty(DOReport.Ud_ReportDoc)

						

				** Il preview del documento lo faccio con il modulo marcato come "UFFICIALE" (che esiste sempre)

				Locate For OfficialReport = .T. 

				If !Found()

					Locate	&& parachiappe

				EndIf  

			

				If lComMgrDebug	&& TODO -> rimuovere in futuro

				   OutputDebugString(Textmerge("[Fedi->PrintDocument]Stampo 1 copia x report <<DOReport.Ud_ReportDoc>> su <<Rtrim(DOReport.Device)>>"))

				EndIf

				

				nCount = 1

				aPrintInfo[1] = NewObjPrintInfo(DOReport.Ud_ReportDoc, 1, RTrim(DOReport.Device), DOReport.SpecialOutput)

			Else

				xMessageBox(Thisform.TB_(,'3575D8FB-C53D-487C-B274-7ACBC33D89F4', "Nessun modulo definito da sfruttare per la generazione del report!"))

			EndIf



		Otherwise

			nCount = 0

			Scan For NumeroCopie > 0 And !Empty(DOReport.Ud_ReportDoc)

				If lComMgrDebug	&& TODO -> rimuovere in futuro

				   OutputDebugString(Textmerge("[Fedi->PrintDocument]Stampo copia <<nCount>> di <<NumeroCopie>> del report <<DOReport.Ud_ReportDoc>> su <<Rtrim(DOReport.Device)>>"))

				EndIf

			

				nCount = nCount + 1

				Dimension aPrintInfo[nCount]

				aPrintInfo[nCount] = NewObjPrintInfo(DOReport.Ud_ReportDoc, DOReport.NumeroCopie, RTrim(DOReport.Device), DOReport.SpecialOutput, DoReport.HtmlContent)

			EndScan

	EndCase

EndIf



If nCount > 0

	oRepDocEng = NewObject1('ReportDoc', 'Libs\ReportDoc.vcx', '', This.Ditta)

	oRepParm   = NewObject0('C_RepParm', 'Progs\ReportEngine.prg')

	oRepParm.CloneFrom(ThisForm.RepParm)

	

	If lComMgrDebug	&& TODO -> rimuovere in futuro

	   OutputDebugString(Textmerge("[Fedi->PrintDocument]Invoco DocPrint"))

	EndIf

	

	oRepDocEng.DocPrint(nId_DoTes, @aPrintInfo, nAction, , oRepParm)

EndIf



If lCloseDOReport

	Use In DOReport

EndIf





ENDPROC

PROCEDURE evalscontocassa

IF THISFORM.SkipRicalcoloScontoCassa

	RETURN

ENDIF



LOCAL cScontoCassa, oRec



oRec = DoTes_Defaults_Sconto_2Obj(DoTes.Cd_DO, DoTes.Cd_CF, DoTes.Cd_CFDest, DoTes.Cd_Agente_1, DoTes.Cd_Agente_2, DoTes.Cd_PG)



cScontoCassa = oRec.ScontoCassa



ThisForm.PF.pgGenerale.PF.pgGenerale.CntPagamento.txtScontoCassa.Field.SetValue(cScontoCassa)



**	LOCAL cFormulaScontoCassam, cOldValue, cNewValue, cAlias

**	LOCAL oPgGenerale



**	oPgGenerale = THISFORM.PF.pgGenerale



**	WITH oPgGenerale.PF.pgGenerale

**		cOldValue = .cntVarie.txtScontoCassa.FIELD.VALUE

**		cFormulaScontoCassa = LOWER(EVAL(oPgGenerale.txtCd_DO.FIELD.FKAlias + '.ScontoCassa'))



**		WITH oPgGenerale.txtCd_CF.FIELD

**			cAlias = .FKAlias

**			IF VARTYPE(.oScontiGruppoClasse) = 'O'

**				WITH .oScontiGruppoClasse

**					cFormulaScontoCassa = STRTRAN(cFormulaScontoCassa, 'clientefamiglia',		.CFFamiglia)

**					cFormulaScontoCassa = STRTRAN(cFormulaScontoCassa, 'clientegruppo',			.CFGruppo)

**					cFormulaScontoCassa = STRTRAN(cFormulaScontoCassa, 'clientesottogruppo',	.CFSottoGruppo)

**					cFormulaScontoCassa = STRTRAN(cFormulaScontoCassa, 'clientecategoria',		.CFCategoria)

**					cFormulaScontoCassa = STRTRAN(cFormulaScontoCassa, 'clienteclasse',			.CFClasse)

**					cFormulaScontoCassa = STRTRAN(cFormulaScontoCassa, 'clientesottoclasse',	.CFSottoClasse)

**				ENDWITH

**			ELSE

**				cFormulaScontoCassa = STRTRAN(cFormulaScontoCassa, 'clientefamiglia',		'')

**				cFormulaScontoCassa = STRTRAN(cFormulaScontoCassa, 'clientegruppo',			'')

**				cFormulaScontoCassa = STRTRAN(cFormulaScontoCassa, 'clientesottogruppo',	'')

**				cFormulaScontoCassa = STRTRAN(cFormulaScontoCassa, 'clientecategoria',		'')

**				cFormulaScontoCassa = STRTRAN(cFormulaScontoCassa, 'clienteclasse',			'')

**				cFormulaScontoCassa = STRTRAN(cFormulaScontoCassa, 'clientesottoclasse',	'')

**			ENDIF

**			cFormulaScontoCassa = STRTRAN(cFormulaScontoCassa, 'cliente',	&cAlias..Sconto)

**		ENDWITH

**		WITH .cntPagamento.txtCd_Agente

**			cAlias = .FIELD.FKAlias

**			cFormulaScontoCassa = STRTRAN(cFormulaScontoCassa, 'agente1',	NVL(&cAlias..Sconto, ''))

**			cAlias = .FIELD1.FKAlias

**			cFormulaScontoCassa = STRTRAN(cFormulaScontoCassa, 'agente2',	NVL(&cAlias..Sconto, ''))

**		ENDWITH

**		cAlias = .cntPagamento.txtCd_PG.FIELD.FKAlias

**		cFormulaScontoCassa = STRTRAN(cFormulaScontoCassa, 'pagamento',	NVL(&cAlias..Sconto, ''))

**		cNewValue = PercStrNormalize(cFormulaScontoCassa)

**		.cntVarie.txtScontoCassa.FIELD.VALUE = cNewValue

**	ENDWITH



** Nessuna interazione con l'utente

** [03/10/2000]

**		IF !(cNewValue == cOldValue)

**			IF !IsEmpty(cOldValue)

**				IF xMessageBox('Sconto Cassa: ' + CRLF + ;

**								'Attuale    : ' + ALLTRIM(cOldValue) + CRLF + ;

**								'Ricalcolato: ' + ALLTRIM(cNewValue) + CRLF + ;

**								'Inserire il nuovo valore ? ', MB_YESNO + MB_ICONQUESTION) = IDYES

**					.cntVarie.txtScontoCassa.FIELD.VALUE = cNewValue

**				ENDIF

**			ELSE

**				.cntVarie.txtScontoCassa.FIELD.VALUE = cNewValue

**			ENDIF	

**		ENDIF	



ENDPROC

PROCEDURE linkintra

Local oForm



ThisForm.ProgBarAdvance(Thisform.ProgressBar.Value + 1, ThisForm.GetDynamicMessage(-1) + ' [Visione Intra]')



If xSQLExists('Intra', 'Id_Dotes = ' + TRAN(Dotes.ID_Dotes))

	oForm = RunFedi('Fedi_Intra', This, , , 0x10, Dotes.ID_Dotes)

	IF VARTYPE(oForm) == 'O'

		oForm.Top  = This.Top  + 20

		oForm.Left = This.Left + 20

		oForm.Show(1)	

	EndIf

EndIf



ENDPROC

PROCEDURE replicadatidorig

LOCAL oForm



oForm = NewObjectWCR2('DoRigReplicator', 'forms\fedi_doccommon.vcx', '', Thisform, Thisform.DOBitmask)	



oForm.Show(1)



ENDPROC

PROCEDURE cmddettagli

Lparameters lQuerySupported



If lQuerySupported

	Return Lower(Thisform.PF.pgGenerale.PF.CurrentPage.Name) == 'pgrighe'

Endif



Thisform.PF.PGgenerale.PF.pgRighe.Cnt.Grid.colDettagli.btnDettaglio.Click()



ENDPROC

PROCEDURE cmdreplica

LPARAMETERS lQuerySupported



IF lQuerySupported

	RETURN (This.Mode != FEDIMODE_SHOW)

ENDIF



THISFORM.ReplicaDatiDoRig()

ENDPROC

PROCEDURE calcspese

#Define CALCSPESE_DOCUMENTO	0x01

#Define CALCSPESE_VARIE			0x02

#Define CALCSPESE_BOLLI			0x04

#Define CALCSPESE_UPDALIVA		0x10

#Define CALCSPESE_ALLDEFS		0x80



** nType -> 0x01 = Spese Documento (Incasso + Effetti)

**				0x02 = Spese Varie (in Cd_DO)

**				0x04 = Spese Bolli (x Edit)

**				0x80 = Forza applicazione default per tutte le righe



Lparameters nType



Local nRet, nOldWA, nRecNo, cDel, cSQL, cDOAlias



cName  	= GetUniqueName()

nOldWA 	= SELECT(0)

cDOAlias = THISFORM.PF.pgGenerale.txtCd_DO.Field.FKAlias



** DOCIVATI : le spese non sono gestite

If DOTes.ImportiIvati Or &cDOAlias..Fte_NotaIva

	Return 

EndIf 



cDel		= ''

cSQL		= ''



**	'T', 'Trasporto      '), ; 0x02

**	'M', 'Imballo        '), ; 0x02

**	'N', 'Incasso        '), ; 0x01

**	'B', 'Bolli          '), ; 0x02

**	'Z', 'Bolli su esenti'), ; 0x04

**	'A', 'Assicurative   '), ; 0x02

**	'V', 'Varie          '), ; 0x02

		

** -------------------- SPESE DOCUMENTO (INCASSO, EFFETTI) -> TIPO N



If Bitand(nType, CALCSPESE_DOCUMENTO) != 0 And INLIST(EVALUATE(ThisForm.PF.pgGenerale.txtCd_DO.Field.FKAlias + '.TipoDocumento'), 'F', 'A', 'N')

	** Elimino soltanto le righe di spesa documento (incasso)

	cDel = cDel + "TipoRigaSpesa == 'N'"

	cSQL = cSQL + 'SELECT * FROM Dbo.DO_SpeseDocumento(' + ;

				Format4Spt(         DoTes.Cd_DO)        + ', ' + ;

				Format4Spt(         DoTes.Cd_PG)        + ', ' + ;

				Format4Spt(         DoTes.Cd_CF)        + ', ' + ;

				Format4Spt(         DoTes.Cd_CFDest)    + ', ' + ;

				Format4Spt(xDefault(DoTes.Cambio,   1)) + ', ' + ;

				Format4Spt(xDefault(DoTes.Decimali, 2)) + ')'



EndIf



** -------------------- SPESE VARIE (TRASPORTO, IMBALLO, BOLLI, ASSICURATIVE, VARIE) -> TIPO T,M,B,A,V != N,Z



If Bitand(nType, CALCSPESE_VARIE) != 0



	** Elimino soltanto le righe di spese varie

	cDel = cDel + Iif(!Empty(cDel), ' Or ', '') + "!(TipoRigaSpesa $ 'NZ')"

	cSQL = cSQL + Iif(!Empty(cSQL), ' Union All ', '') + 'SELECT * FROM Dbo.DO_SpeseVarie(' + ;

				Format4Spt(         DoTes.Cd_DO)        + ', ' + ;

				Format4Spt(         DoTes.Cd_CF)        + ', ' + ;

				Format4Spt(         DoTes.Cd_CFDest)    + ', ' + ;

				Format4Spt(xDefault(DoTes.Cambio,   1)) + ', ' + ;

				Format4Spt(xDefault(DoTes.Decimali, 2)) + ')'



EndIf



** -------------------- SPESE BOLLI



If Bitand(nType, CALCSPESE_BOLLI) != 0



	Local oTotali

	oTotali = Thisform.TotaleDocumento()

	

	** Elimino soltanto le righe di spese varie

	cDel = cDel + Iif(!Empty(cDel), ' Or ', '') + "TipoRigaSpesa == 'Z'"

	cSQL = cSQL + Iif(!Empty(cSQL), ' Union All ', '') + 'SELECT * FROM Dbo.DO_SpeseBolliEsenzione(' + ;

				Format4Spt(         DoTes.Cd_DO)        + ', ' + ;

				Format4Spt(         DoTes.Cd_CF)        + ', ' + ;

				Format4Spt(oTotali.TotEsenteBolloV)     + ', ' + ;

				Format4Spt(xDefault(DoTes.Cambio,   1)) + ', ' + ;

				Format4Spt(xDefault(DoTes.Decimali, 2)) + ')'



EndIf



nRet = xSQLExec(Stmt4SQLExec(cSQL), cName)



If Used(cName)



	REPLACE Riga WITH RECNO(cName) + 1000 ALL IN (cName)

	

	If Bitand(nType, CALCSPESE_UPDALIVA) != 0

		

		Local oRecDef

		Local lChanged, lNeedModify

		Local cStmt, cMsg

		

		** -----------------------------------------------------------------------------

		** Devo controllare se le righe spese sono state modificate dall'utente...				



		Select DoRigSpesa

		Scan For &cDel

			Select (cName)

			Locate For 	TipoRigaSpesa 	= DoRigSpesa.TipoRigaSpesa And ;

							Descrizione		= DoRigSpesa.Descrizione  	And ;

							ImportoV 		= DoRigSpesa.ImportoV   	And ;

							Perc 				= DoRigSpesa.Perc   			And ;

							Cd_CGConto 		= DoRigSpesa.Cd_CGConto 



			If !Found()			

				lChanged = .T.		&& la riga spesa del documento è stata modificata rispetto a quelle di default: dovrò chiedere conferma all'utente

			EndIf 

		EndScan  



		If !lChanged And Thisform.Mode = FEDIMODE_INS

			

			** Le righe spesa NON hanno subito modifiche da parte dell'utente. Mi assicuro che l'aliquota IVA sia quella di Default (ricavata dalle TvF dbo.DO_SpeseVarie / dbo.DO_SpeseDocumento )

			** NB: qua dentro entro solo in inserimento documento: in fase di modifica di un documento chiedo sempre la conferma...

						

			Select DoRigSpesa

			Scan For &cDel

				Select (cName)

				Locate For 	TipoRigaSpesa 	= DoRigSpesa.TipoRigaSpesa And ;

								Descrizione		= DoRigSpesa.Descrizione  	And ;

								ImportoV 		= DoRigSpesa.ImportoV   	And ;

								Perc 				= DoRigSpesa.Perc   			And ;

								Cd_CGConto 		= DoRigSpesa.Cd_CGConto 



				If Found() And !SafeCompare(DoRigSpesa.Cd_Aliquota, &cName..Cd_Aliquota)

					Replace Cd_Aliquota With Nvl(&cName..Cd_Aliquota, '') In DoRigSpesa

				EndIf 

			EndScan  



		Else

		

			** Le righe spesa hanno subito modifiche

		

			Create Cursor _tmpInfo(TipoRigaSpesa C(1), Cd_AliquotaOld C(3), Cd_AliquotaNew C(3))	&& questo cursore mi server per comporre il msg



			** Controllo se ci sono righe spese con aliquota diversa dal valore di Default (ricavato da DoRigSpesa_Defaults_AliquotaConto_2Obj perchè non ho più nessuna corrispondenza con le spese ricavate da dbo.DO_SpeseVarie )



			Select DoRigSpesa

			Scan For &cDel

				oRecDef = DoRigSpesa_Defaults_AliquotaConto_2Obj(DoRigSpesa.TipoRigaSpesa, DOTes.Cd_DO, DOTes.Cd_CF, DOTes.Cd_CFDest)

				If  !SafeCompare(DoRigSpesa.Cd_Aliquota, oRecDef.Cd_Aliquota)

					lNeedModify = .T.

					Insert Into _tmpInfo(			  TipoRigaSpesa, 				 Cd_AliquotaOld, 		 Cd_AliquotaNew)  ;

									Values  (DoRigSpesa.TipoRigaSpesa, DoRigSpesa.Cd_Aliquota, Nvl(oRecDef.Cd_Aliquota,''))

				EndIf 

			EndScan 



			If lNeedModify

						

				** Creo il messaggio



				cMsg = ''

				                            

            	Select Distinct TipoRigaSpesa, Cd_AliquotaNew From _tmpInfo Order by TipoRigaSpesa Into Cursor _tmpInfo         && controllo se la nuova aliquota è sempre la stessa

				Scan

					cMsg = cMsg + 'per le spese di ' + ICase(	TipoRigaSpesa = 'T', 'Trasporto',       ; 

																			TipoRigaSpesa = 'M', 'Imballo',         ;

																			TipoRigaSpesa = 'N', 'Incasso',         ;

																			TipoRigaSpesa = 'B', 'Bolli Incasso',   ;

																			TipoRigaSpesa = 'Z', 'Bolli su Esenti', ;

																			TipoRigaSpesa = 'A', 'Assicurative',    ;

																			TipoRigaSpesa = 'V', 'Varie') + ' codice "' +  NEvl(_tmpInfo.Cd_AliquotaNew, '')+ '";' + CRLF 

				EndScan 

  

  				Text To cMsg TextMerge NoShow Pretext 1+2

					È stata modificata la Sede Operativa: questa operazione influenzerà i codici IVA che verranno proposti nelle future righe di spesa.

					  

					Vuoi modificare le attuali righe di spesa impostando i seguenti codici IVA?

					  

					<<cMsg>>

					N.B.: le righe di spesa "Bolli su Esenti" sono escluse da questa elaborazione.

				EndText 

			

				** Procedo con l'update ********************************************************************



				If xMessageBox(cMsg, 4+32) = 6	



					Select DoRigSpesa

					Scan For &cDel

						oRecDef = DoRigSpesa_Defaults_AliquotaConto_2Obj(DoRigSpesa.TipoRigaSpesa, DOTes.Cd_DO, DOTes.Cd_CF, DOTes.Cd_CFDest)

						Replace 	Cd_Aliquota With Nvl(oRecDef.Cd_Aliquota,'') In DoRigSpesa

					EndScan 	



				EndIf 

					

			EndIf 

			

			** Chiudo le WA

			Use In Select('_tmpInfo')



		EndIf 

		

	Else



		** 21/02/2002 devo cancellare le vecchie righe anche se non ne ho di nuove da proporre...

		**	IF RECCOUNT(cName) > 0



		SELECT DoRigSpesa

		DELETE FOR &cDel IN DoRigSpesa

		IF THIS.Mode != FEDIMODE_INS_DUP AND THIS.ModeFromprelievo = 0

			THISFORM.PF.pgGenerale.PF.pgpiede.cnt.cntFattura.Grid.SaveRecordSource()

		ENDIF

		APPEND FROM DBF(cName)



		REPLACE ImportoEvadibileV WITH ImportoV ALL IN DoRigSpesa

	EndIf 

	

	**	ENDIF

	Use In (Select(cName))



	** Default per CA

	** Il prelievo dei documenti deve limitarsi a prelevare i dati e applico i defaults solo alle righe nuove,

	** quelle con numero riga > 1000 (Il rinumera riga deve stare alla fine)

	

	** ----- LICADAPTER

	If &cDOAlias..CAEnabled And oApp.LicInfo.CA_Main



		Local oRec, oDef

		

		Select DoRigSpesa

		Scan For Riga > 1000 Or Bitand(nType, CALCSPESE_ALLDEFS) != 0

			oRec = DoRig_Defaults_CA_2Obj(DoTes.Cd_DO, DoTes.Cd_CF, DoTes.Cd_CFDest, Null, DoRigSpesa.Cd_CGConto)

			

			Replace 	Cd_CAVda 		With oRec.Cd_CAVda, ;

						Cd_CACda 		With oRec.Cd_CACda, ;

						Cd_CAFormula 	With oRec.Cd_CAFormula, ;

						CAPartenza 		With oRec.CAPartenza, ;

						CADurata 		With oRec.CADurata ;

						In DoRigSpesa

			

			If Thisform.DE.Preferenza.CACGPeriodo

				oDef = RR_GetDefaults_DO(DoTes.Cd_DO, DoRigSpesa.Cd_CGConto, DOTes.DataDoc)

				Replace DataInizioComp 	With oDef.RR_DataInizio ;

						DataFineComp   	With oDef.RR_DataFine   ;

				In DoRigSpesa

			EndIf

		

		EndScan

		

	EndIf

	

	THISFORM.RinumeraRighe('DoRigSpesa')

	

	GO TOP IN DoRigSpesa

	IF THIS.Mode != FEDIMODE_INS_DUP AND THIS.ModeFromprelievo = 0

		THISFORM.PF.pgGenerale.PF.pgpiede.cnt.cntFattura.Grid.RestoreRecordSource()

	ENDIF



	** Applico DI

	** Alla prima applicazione (Cd_DO.OnvalueChange()) non è presente il CD_CF per cui esce subito dalla procedura in quanto non applicabile)



	Select DoRigSpesa

	Scan

		THISFORM.PF.pgGenerale.PF.pgpiede.cnt.SetDorigSpesa_Defaults_DI('FOR')

	EndScan

	

ENDIF



GO TOP IN DoRigSpesa

SELECT (nOldWa)



ENDPROC

PROCEDURE cmdcopiada

LParameters lQuerySupported



If lQuerySupported

	Return ThisForm.Mode != FEDIMODE_SHOW

EndIf



Local oForm, oRecDO, oRecMGCausale

Local nDec, nDecPrzUn



If Empty(DoTes.Cd_VL)

	xMessageBox(Thisform.TB_(,'9B184B5A-E967-449E-875D-01E675131628', 'Selezionare la valuta del documento'))

	Return

EndIf



** BUG 3588: se sono posizionato nella griglia, faccio in modo di spostare il focus del tab del PF.

If This.PF.pgGenerale.PF.ActivePage = 2	&& pgRighe

	This.PF.pgGenerale.PF.pgRighe.SetFocus()

EndIf 



oForm = RunCmd('cmd_DOCopiaDa', ThisForm, DoTes.Cd_VL, DoTes.ID_DoTes, DoTes.DataDoc)



** DOCIVATI

oForm.PF.pgGenerale.cnt.chkImportiIvati.SetValue( Iif(DoTes.ImportiIvati, 1, 0) )

oForm.PF.pgGenerale.cnt.chkImportiIvati.Enabled = .F.



oForm.HideOnClose = .T.

oForm.Show(1)



With ThisForm.PF.pgGenerale.txtCd_VL.Field

	nDec     	= Eval(.FKAlias + '.Decimali'     )

	nDecPrzUn 	= Eval(.FKAlias + '.DecimaliPrzUn')

EndWith



If Vartype(oForm) = 'O' And PemStatus(oForm, 'Ids', 5) And !IsEmpty(oForm.Ids)



	xSqlExec('SELECT ' + ColumnsList('DoRig', 'DoRig', 'NoteRiga,Matricole') + ", NoteRiga = Convert(Text, IsNull(NoteRiga, '')), Matricole = Convert(VarChar(Max), Matricole), DoRig.Id_DoRig AS Id_DoRig_Rif FROM DoRig WHERE Id_DoRig IN (" + SubStr(oForm.Ids, 3) + ') Order By DoRig.Id_DoTes, DoRig.Riga', 'DoRig_tmp')



	oRecDO = ThisForm.PF.pgGenerale.txtCd_DO.Field.FKRecord

	

	** ----- INIZIO controllo commessa: se nella testa del documento c'è una commessa, verifico le commesse presenti nelle righe copiate

	Local lCommDiversa

	lCommDiversa = .F.

	IF !IsEmpty(DOTes.CD_DOSottoCommessa)



		Select CD_DOSottoCommessa FROM DoRig_tmp GROUP BY CD_DOSottoCommessa WHERE !IsEmpty(DoRig_tmp.CD_DOSottoCommessa) INTO CURSOR crDoRig_tmp_Commesse 



		DO Case

			Case _Tally = 0	&& Se non ci sono commesse nelle righe, non avviso



			Case _Tally = 1	&& Se c'è la stessa commessa in tutte le righe, avviso solo se è diversa da quella della testa

				If DOTes.CD_DOSottoCommessa <> crDoRig_tmp_Commesse.CD_DOSottoCommessa 

					lCommDiversa = .T.

				EndIf



			Case _Tally > 1	&& Se nelle righe ci sono commesse diverse avviso 

				lCommDiversa = .T.



		EndCase		



		IF lCommDiversa

			IF xMessagebox("ATTENZIONE: nella testa del documento è stata inserita una commessa diversa da quella delle righe copiate. " + CHR(13) + ;

								"Se si desidera proseguire con la copia delle righe, la commessa di testa sarà riportata in tutte le righe copiate." + CHR(13) + ;

								"Confermi l'operazione ?",  4 + 32) <> 6

				Use In DoRig_tmp

				Iif(Vartype(oForm) = 'O', oForm.Release(), .T.)

				Return

			EndIf

		ENDIF



		Use In crDoRig_tmp_Commesse 

		Replace All CD_DOSottoCommessa WITH DOTes.CD_DOSottoCommessa IN DoRig_tmp 

	EndIf

	** ----- FINE controllo commessa: se nella testa del documento c'è una commessa, verifico le commesse presenti nelle righe copiate



	** ----- LICADAPTER

	If !(oForm.CopiaMatricole And oRecDO.MtrEnabled And oApp.LicInfo.DO_LottiMatr)

		Replace Matricole With Null For !IsEmpty(Matricole) In DoRig_tmp 

	EndIf



	If oForm.CopiaPackList And oRecDO.PkLstEnabled

		xSqlExec('SELECT DoRigPackList.* FROM DoRigPackList WHERE Id_DoRig IN (' + SubStr(oForm.Ids, 3) + ')', 'DoRigPackLst_tmp')

	EndIf



	Local nRigaMax, nRec, nPrezzo, nPrezzoAddizionale, nId_LSArticolo, nId_LSScaglione

	Local oRec, oRecAli

	Local cSconto, cScontoAddizionale, cProvvigione_1, cProvvigione_2

	Local nFattoreScontoTotale



	Select DoRig

	nRec = RecNo()

	Calculate Max(Riga) To nRigaMax

	nRigaMax = nRigaMax +1

	Select DoRig_tmp

	nRecTot = RecCount()

	ThisForm.ProgBarShow(0, nRecTot, '')



	Scan

		nRec = RecNo()

		ThisForm.ProgBarAdvance(RecNo(), 'Copia Righe [' + Tran(nRec, '####' ) +  '/' + Tran(nRecTot, '####' ) +  ']')

		

		Scatter Fields Except Id_DoRig, ID_DoTes, QtaEvasa, ID_DoRig_Evade, Cd_DO, NumeroDoc, DataDoc Name oRec Memo



		** Controllo se il documento corrente supporta la colonna P/C

		If This.PF.PgGenerale.PF.PgRighe.cnt.Grid.ColTipoPC.Visible = .F.

			oRec.TipoPC = ''

		EndIf 

		

		oRec.QtaEvadibile	= oRec.Qta

		If !oForm.CopiaDataConsegna

			oRec.DataConsegna = DoTes.DataConsegna

		Else

			oRec.DataConsegna = Max(Nvl(DoTes.DataConsegna, {}), Nvl(oRec.DataConsegna, {}))

		EndIf



		If !oForm.CopiaLotti

			oRec.Cd_ARLotto = Null

		EndIf 



		If !IsEmpty(oRec.Cd_AR) And (!oForm.CopiaPrezzi Or !oForm.CopiaSconti Or !oForm.CopiaProvvigioni Or !oForm.CopiaAnalitica Or !oForm.CopiaAliquotaConto)

			Local oRecDD



			oRecDD = DoRig_Defaults_2Obj(;

				DoTes.Cd_DO, ;

				DoTes.CD_CF, ;

				DoTes.DataDoc, ;

				oRec.DataConsegna, ;

				DoTes.Cd_CFDest, ;

				DoTes.Cd_Agente_1, ;

				DoTes.Cd_Agente_2, ;

				DoTes.Cd_PG, ;

				DoTes.Cd_LS_1, ;

				DoTes.Cd_LS_2, ;

				DoTes.Cd_VL, ;

				DoTes.Cambio, ;

				oRec.Cd_AR, ;

				oRec.Qta, ;

				oRec.Cd_ARMisura, ;

				oRec.FattoreToUM1, ;

				oRec.Cd_DOSottoCommessa)

				

			If !oForm.CopiaAliquotaConto



				oRec.Cd_CGConto 			= oRecDD.Cd_CGConto

				oRec.Cd_Aliquota			= oRecDD.Cd_Aliquota

				oRec.Cd_ReverseCharge	= oRecDD.Cd_ReverseCharge



			EndIf

			

			If !oForm.CopiaAnalitica

				oRec.Cd_CAVda		= oRecDD.Cd_CAVda

				oRec.Cd_CACda		= oRecDD.Cd_CACda

				oRec.Cd_CAFormula	= oRecDD.Cd_CAFormula

				oRec.CAPartenza	= oRecDD.CAPartenza

				oRec.CADurata		= oRecDD.CADurata

			endif

			

			If !oForm.CopiaSconti

				oRec.ScontoRiga			= oRecDD.Sconto

				oRec.ScontoAddizionale	= oRecDD.ScontoAddizionale

			EndIf



			If !oForm.CopiaProvvigioni

				oRec.ProvvigioneRiga_1	= oRecDD.Provvigione_1

				oRec.ProvvigioneRiga_2	= oRecDD.Provvigione_2

			EndIf



			If !oForm.CopiaPrezzi

				oRec.PrezzoUnitarioV		= oRecDD.Prezzo

				oRec.PrezzoAddizionaleV	= oRecDD.PrezzoAddizionale

				oRec.Id_LSArticolo	   = oRecDD.Id_LSArticolo

				oRec.Id_LSScaglione		= oRecDD.Id_LSScaglione

				

				oRec.PrezzoUnitarioScontatoV	= xRound(oRec.PrezzoUnitarioV * PercStrEvalC(PercStrNormalize(oRec.ScontoRiga + '+' + oRec.ScontoAddizionale)), oRec.DecimaliPrzUn)

			EndIf



			** BUG 5991

*			oRec.PrezzoTotaleV = DoRig_PrezzoTotaleV(oRec.Qta, oRec.PrezzoUnitarioV, PercStrEvalA(PercStrNormalize(oRec.ScontoRiga + '+' + oRec.ScontoAddizionale)), oRec.PrezzoAddizionaleV, oRec.Decimali, oRec.Cambio) 

			nFattoreScontoTotale	 = 1 - PercStrEvalCD(oRec.ScontoRiga) * PercStrEvalCD(oRec.ScontoAddizionale)

			oRec.PrezzoTotaleV 	 = DoRig_PrezzoTotaleV(oRec.Qta, oRec.PrezzoUnitarioV, nFattoreScontoTotale, oRec.PrezzoAddizionaleV, oRec.Decimali, oRec.Cambio) 

			

			oRec.NoteRiga = IIF(ISNULL(NoteRiga),'',NoteRiga)

		EndIf



		** ----- LICADAPTER

		If oApp.LicInfo.MG_Main



			oRecMGCausale = xSqlExec2Obj(TextMerge('Select * From MGCausale Where Cd_MGCausale = <<Format4Spt(oRecDO.Cd_MGCausale)>>'))

			If Vartype(oRecMGCausale) = 'O'

				If oRecMGCausale.UIMagPFix

					oRec.Cd_MG_P = oRecMGCausale.Cd_MG_P

				EndIf



				If oRecMGCausale.UIMagAFix

					oRec.Cd_MG_A = oRecMGCausale.Cd_MG_A

				EndIf

			EndIf

		

		EndIf



		If !oForm.CopiaDistinte

			oRec.Id_DODB = Null

		Endif



		oRec.Riga = nRigaMax

		nRigaMax	= nRigaMax +1

		

		** scrittura della riga documento

		Select DoRig

		Append Blank

		Gather Name oRec Memo



		** ----- LICADAPTER

		** Controllo giacenza		

		If oApp.LicInfo.MG_Main

			Local nQtaOld, nQtaNew

			Local lForce, lCommessaChanged, lPrezzoChanged, lScontoChanged, lProvvigione1Changed

			nQtaOld = oRec.Qta

			nQtaNew = Thisform.PF.pgGenerale.PF.pgRighe.cnt.ControlloGiacenza()

			If nQtaNew <> nQtaOld 	

				** Sistemazione quantità, quantità evasa, evadibile, prezzo, sconto, provvigione ...

				Thisform.PF.pgGenerale.PF.pgRighe.cnt.SetDoRig_Quantita(nQtaNew, nQtaOld)			

				lForce					= .F.

				lCommessaChanged		= .F. 

				lPrezzoChanged       = Thisform.PF.pgGenerale.PF.pgRighe.cnt.SetDoRig_Prezzo		 (nQtaNew, nQtaOld, @lForce)	&& lForce: per ricalcolare Sconti e Provv in base allo scaglione...

				lScontoChanged       = Thisform.PF.pgGenerale.PF.pgRighe.cnt.SetDORig_Sconto		 (lForce, !lCommessaChanged, !lPrezzoChanged)

				lProvvigione1Changed = Thisform.PF.pgGenerale.PF.pgRighe.cnt.SetDORig_Provvigione1(lForce, !lCommessaChanged, !lPrezzoChanged, !lScontoChanged)

				                       Thisform.PF.pgGenerale.PF.pgRighe.cnt.SetDORig_Provvigione2(lForce, !lCommessaChanged, !lPrezzoChanged, !lScontoChanged, !lProvvigione1Changed)

			EndIf 

		EndIf

		

		If Used('DoRigPackLst_tmp')

			Select DoRigPackLst_tmp

			Scan For Id_DoRig = oRec.Id_DoRig_Rif

				Replace Id_DoRig With RecNo('DoRig')

			EndScan

		EndIf



		If oForm.CopiaDistinte And !IsEmpty(oRec.Id_DODB)

			Thisform.DuplicateCustomDB(oRec.Id_DODB)

		Endif 

		

		** Riporto alcuni dati legati all'aliquota e non visibili in grid (Vedi OnValueChange)

		If !IsEmpty(oRec.Cd_Aliquota)



			oRecAli = xSQLExec2Obj('Select Cd_ReverseCharge, IvaMoss, IvaSplit From Aliquota Where Cd_Aliquota = ' + FormatC4SPT(oRec.Cd_Aliquota))

			If Vartype(oRecAli) == 'O'

				Replace Cd_RC With oRecAli.Cd_ReverseCharge, IvaMoss With oRecAli.IvaMoss, IvaSplit With oRecAli.IvaSplit In DoRig

				Replace Cd_ReverseCharge With xDefault(DoTes.Cd_ReverseCharge, xDefault(Dorig.Cd_ReverseCharge, Dorig.Cd_RC)) In Dorig

			EndIf

		

		EndIf

		

		** Applico DI

		Iif(PemStatus(This.PF.pgGenerale.PF.pgRighe.Cnt.Grid.ColDoIntento.StdText1, 'SkipCheck', 5), RemoveProperty(This.PF.pgGenerale.PF.pgRighe.Cnt.Grid.ColDoIntento.StdText1, 'SkipCheck'), .T.)

		This.PF.pgGenerale.PF.pgRighe.Cnt.Setdorig_Defaults_DI('FOR')

		

		Select DoRig_tmp



	EndScan

	

	If Used('DoRigPackLst_tmp')

		Select DoRigPackList

		Append From (Dbf('DoRigPackLst_tmp'))

		Use In DoRigPackLst_tmp

	EndIf



	ThisForm.ProgBarHide()



	Select DoRig



	Locate Record (nRec)



	** In VFP8 non si può fare Refresh() perchè se la griglia non è visibile il Refresh viene ignorato

	This.PF.pgGenerale.PF.pgRighe.Cnt.Grid.SaveRecordSource()

	This.PF.pgGenerale.PF.pgRighe.Cnt.Grid.RestoreRecordSource()



	Use In DoRig_tmp



	** Riapplico RC

	** Thisform.SetRegimeIva('TIPOFATTURA')



	This.PF.pgGenerale.PF.pgRighe.cnt.Grid.DoScroll(2)	

	This.PF.pgGenerale.PF.pgRighe.cnt.Grid.Refresh()

	

EndIf



Iif(Vartype(oForm) = 'O', oForm.Release(), .T.)



ENDPROC

PROCEDURE linksc

LOCAL oForm, nCounter, nId_Parent



ThisForm.ProgBarAdvance(Thisform.ProgressBar.Value + 1, ThisForm.GetDynamicMessage(-1) + ' [Visione scadenze]')



nId_Parent	= Evl(DoTes.ID_DoTes, 0)

nCounter 	= Iif(nId_Parent != 0, xSqlExec2Var("SELECT COUNT(*) AS Counter FROM Sc WHERE Sc.Id_Dotes = " + TRAN(nId_Parent)), 0)



IF nCounter > 0

	oForm = RunFedi('Fedi_Sc', ThisForm, 'SC.Id_Dotes = ' + TRAN(nId_Parent) + ' And Sc.Insoluta = 0', , 'DO', nId_Parent)

	IF VARTYPE(oForm) == 'O'

		oForm.Top  = This.Top  + 20

		oForm.Left = This.Left + 20

		oForm.Toolbar.Buttons('NEW').Enabled = .F.

		

		** Utilizzo sia Visible .T. che Show(1) in quanto senza visible la form non viene visualizzata

		** nemmeno forzando da Cmd Window lo show(), e senza show(1) parte in modalità Modeless anche

		** se la classe ha ben specificato WindowType = 1.

		** Non so se è un problema dovuto al fatto che il presente metodo viene richiamato dal .Save

		** che viene a sua volta richiamato dalla toolbar che essendo un ActiveX ......

		** oForm.Visible = .T.

		oForm.Show(1)

	Else

		xMessageBox(MSG_POLICY_DENYFRM, MB_OK + MB_ICONSTOP)

	EndIf

EndIf



Return .T.







ENDPROC

PROCEDURE cmdviewcg

LOCAL oForm



If !oApp.LicInfo.CG_Main

	Return .F.

EndIf



If !xSQLExists('CGMovT', 'ID_DoTes = ' + Tran(DoTes.ID_DoTes))

	xMessageBox(Thisform.TB_(,'9F6DF039-0C16-45FD-8449-7864E9E61357', 'Il documento non ha movimento contabile collegato.'))

	RETURN .F.

ENDIF



oForm = RunFedi('Fedi_CGMovT', ThisForm, 'CgMovT.Id_DoTes = ' + TRAN(DoTes.ID_DoTes))



IF VARTYPE(oForm) == 'O'

	oForm.CmdPgGenerale()

	oForm.PF.PGElenco.Enabled = .F.

	oForm.Toolbar.Buttons('NEW').Enabled  	= .F.

	oForm.Show(1)

	

	This.DE.DoTes.RequeryCurrent()

	This.OnRecordChange()		&& mi serve per aggiornare i bottoni della Toolbar

EndIf



ENDPROC

PROCEDURE cmdviewscadenza

Local oForm, nCounter, nId_Parent



If !InList(DoTes.TipoDocumento, 'F','A','N')

	Return .F.

EndIf 



nId_Parent 	= Abs(DoTes.ID_DoTes)

nCounter 	= xSqlExec2Var("SELECT COUNT(*) AS Counter FROM Sc WHERE Sc.Id_Dotes = " + Tran(nId_Parent))



oForm = RunFedi('Fedi_Sc', Thisform, 'Sc.Id_Dotes = ' + Tran(nId_Parent) + ' And Sc.Insoluta = 0', , 'DO', nId_Parent)

If Vartype(oForm) == 'O'

	Iif(nCounter = 1, oForm.CmdPgGenerale(), .T.)

	oForm.Show(1)

Else

	xMessageBox(MSG_POLICY_DENYFRM, MB_OK + MB_ICONSTOP)

Endif



ENDPROC

PROCEDURE cmdviewintra

LOCAL oForm



** La funzione non è accessibile in INS

** Permetto di vedere le righe intra in caso il documento sia fattura UE/Esecutiva o vi siano precedenti righe elaborate.

If xSQLExists('Intra', 'ID_DoTes = ' + Tran(DoTes.ID_DoTes)) Or (InList(DoTes.TipoDocumento, 'F', 'A', 'N') And Dotes.UE And Dotes.Esecutivo)

	oForm = RunFedi('Fedi_Intra', This, , , 0x10, DoTes.ID_DoTes)

	Iif(Vartype(oForm) == 'O', oForm.Show(1), .T.)

Else

	xMessageBox(Thisform.TB_(,'392E35D9-4224-4AF6-97FE-8330EE513F31', 'Funzionalità non disponibile.'))

	Return .F.

EndIf



ENDPROC

PROCEDURE totaledocumento

Local lSpeseBolliAuto



lSpeseBolliAuto = PemStatus(ThisForm.PF.PGGenerale.PF.PgPiede, 'Cnt', 5) And ThisForm.PF.PGGenerale.PF.PgPiede.Cnt.cntFattura.chkSpeseBolli.Visible And ThisForm.PF.PGGenerale.PF.PgPiede.Cnt.cntFattura.chkSpeseBolli.Value



Return Fedi_DOC_TotaleDocumento(lSpeseBolliAuto)







ENDPROC

PROCEDURE cmddodbconverti

Lparameters lQuerySupported, nConvertType, lSilent



Local lRet



lRet = (Thisform.Mode != FEDIMODE_SHOW)											And ;

	(Lower(Thisform.PF.pgGenerale.PF.CurrentPage.Name) == 'pgrighe')	And ;

	(!Eof('DoRig') And !IsEmpty(DoRig.Cd_AR))



If lQuerySupported

	Return lRet

Endif



If lRet



	Local nOldWA, nDecimaliQta

	Local cStmt

	Local lExistDB, lExistDoDB, lOk

	Local tDataConsegna, tDataExpl



	nDecimaliQta = This.DE.Preferenza.DecimaliQta



	nOldWA = Select(0)

	Do While .T.



		** Devo verificare se l'articolo ha distinta standard o custom

		lExistDB   = !Isnull(xSqlExec2Obj('Select * From DB Where Cd_AR = ' + Format4Spt(DoRig.Cd_AR)))

		lExistDoDB = !IsEmpty(DoRig.Id_DoDB)



		If !lExistDoDB And !lExistDB

			xMessageBox(Thisform.TB_(,'9EC7D492-595D-426D-A59D-571AD3F887C8', "L'articolo considerato non possiede distinta base!"), MB_ICONINFORMATION)

			Exit

		Endif



		If lExistDoDB

			lOk = lSilent Or (xMessageBox(Thisform.TB_(,'6EE5B40A-5017-4625-A860-BAE40D075300', "Convertire in righe documento la distinta custom associata all'articolo?"), MB_YESNO + MB_ICONQUESTION) = IDYES)

			If lOk

				lExistDB = .F.

			Else

				Exit

			Endif

		Endif



		If lExistDB

			lOk = lSilent Or (xMessageBox(Thisform.TB_(,'0970B806-2047-4D53-8705-C620A1214041', "Convertire in righe documento la distinta standard associata all'articolo?"), MB_YESNO + MB_ICONQUESTION) = IDYES)

			If lOk

				tDataExpl = Evl(Nvl(DoRig.DataConsegna, ''), DoTes.DataDoc)

				lExistDoDB = .F.

			Else

				Exit

			Endif

		Endif



		** A questo punto la variabile tra le due lExistDoDB e lExistDB che vale .T. indica quale

		** distinta devo convertire in righe documento



		If lExistDoDB



			** Problema: in questo caso la distinta potrebbe essere stata creata/modificata sul client

			** e quindi non è disponibile sul server; allora occorre ricavare l'elenco dei materiali

			** sul client tenendo conto dei componenti fantasma; intanto creo il cursore vuoto ma con il

			** tracciato corretto



			Local cAlias0, cAlias1, cAlias2



			cAlias0 = 'a' + Sys(2015)

			cAlias1 = 'b' + Sys(2015)

			cAlias2 = 'c' + Sys(2015)



			TEXT To cStmt TextMerge NoShow



				Select

					M.*,

					AR.Descrizione,

					ARARMisura.Cd_ARMisura

				From DBListaMateriali4Mg(Null, << Format4Spt(DoRig.Id_DoDB) >>, << Format4Spt(tDataExpl) >>) M

				Inner Join AR         On M.Cd_AR  = AR.Cd_AR

				Inner Join ARARMisura On AR.Cd_AR = ARARMisura.Cd_AR And ARARMisura.DefaultMisura = 1

				Where 1=0



			ENDTEXT

			xSqlExec(cStmt, cAlias0)



			** Caricamento progressivo delle distinte documento; lo faccio anche qui oltre che in DoDBEdit

			** perchè non so se la distinta custom è già stata caricata

			Thisform.DE.DoDB.Requery         ('Id_DoDB = ' + Format4Spt(DoRig.Id_DoDB),, .T.)

			Thisform.DE.DoDBAttivita.Requery ('Id_DoDB = ' + Format4Spt(DoRig.Id_DoDB),, .T.)

			Thisform.DE.DoDBMateriale.Requery('Id_DoDB = ' + Format4Spt(DoRig.Id_DoDB),, .T.)



			** Attenzione: a causa del buffering non posso fare una select, quindi devo lavorare di x-base;

			** fortunatamente però il cursore DoDBMateriale viene già costruito con il campo replicato Id_DoDB

			** quindi non devo riprodurre la Join con DoDBAttivita ma posso andare diretto



			** Preparo il cursore con il tracciato corretto

			Select																						;

				DBFantasma,																				;

				Cd_AR,																					;

				ConsumoUM1,																				;

				Descrizione,																			;

				Cd_ARMisura																				;

				From DoDBMateriale																		;

				Where 1=0																					;

				Into Cursor (cAlias1) Readwrite



			** Aggiungo al cursore tutti i record che mi interessano

			Select DoDBMateriale

			Scan For Id_DoDB = DoRig.Id_DoDB

				Select (cAlias1)

				Append Blank

				Replace 																					;

					DBFantasma	With DoDBMateriale.DBFantasma,								;

					Cd_AR			With DoDBMateriale.Cd_AR,										;

					ConsumoUM1	With DoDBMateriale.ConsumoUM1,								;

					Descrizione	With DoDBMateriale.Descrizione,								;

					Cd_ARMisura	With DoDBMateriale.Cd_ARMisura								;

					In (cAlias1)

			Endscan



			Select (cAlias1)

			Scan



				If !DBFantasma

					Select (cAlias0)

					Append Blank

					Replace																				;

						Cd_AR			With Eval(cAlias1 + '.Cd_AR'),							;

						Consumo		With Eval(cAlias1 + '.ConsumoUM1'),						;

						Descrizione	With Eval(cAlias1 + '.Descrizione'),					;

						Cd_ARMisura	With Eval(cAlias1 + '.Cd_ARMisura')						;

						In (cAlias0)

				Else



					TEXT To cStmt TextMerge NoShow



						Select

							M.*,

							AR.Descrizione,

							ARARMisura.Cd_ARMisura

						From DBListaMateriali4Mg(<< Format4Spt(Eval(cAlias1 + '.Cd_AR')) >>, Null, << Format4Spt(tDataExpl) >>) M

						Inner Join AR         On M.Cd_AR  = AR.Cd_AR

						Inner Join ARARMisura On AR.Cd_AR = ARARMisura.Cd_AR And ARARMisura.DefaultMisura = 1



					ENDTEXT



					xSqlExec(cStmt, cAlias2)



					Select (cAlias2)

					Scan

						Select (cAlias0)

						Append Blank

						Replace	Cd_AR			With Eval(cAlias2 + '.Cd_AR'),			;

							Consumo		With Eval(cAlias2 + '.Consumo'),			;

							Descrizione	With Eval(cAlias2 + '.Descrizione'),	;

							Cd_ARMisura	With Eval(cAlias2 + '.Cd_ARMisura')		In (cAlias0)

					Endscan



				Endif



			Endscan



			** cAlias0 è un SPT quindi con buffer a 3; per evitare problemi nelle successive

			** select è bene svuotare il buffer con un TableUpdate()

			Tableupdate(.T., .F., cAlias0)



			** Adesso raggruppo gli articoli (l'uso del Max è un trucco per estrarre i campi)



			Select																							;

				Cd_AR				 	As Cd_AR,															;

				Sum(Consumo) 		As Consumo,															;

				Max(Descrizione)	As Descrizione,													;

				Max(Cd_ARMisura)	As Cd_ARMisura														;

				From (cAlias0)																					;

				Group By Cd_AR																					;

				Into Cursor Materiali



			Use In (Select(cAlias0))

			Use In (Select(cAlias1))

			Use In (Select(cAlias2))



		Endif



		If lExistDB



			TEXT To cStmt TextMerge NoShow



				Select

					M.*,

					AR.Descrizione,

					IsNull(ARARMisura.Cd_ARMisura, '**') As Cd_ARMisura

				From DBListaMateriali4Mg(<< Format4Spt(DoRig.Cd_AR) >>, Null, << Format4Spt(tDataExpl) >>) M

				Inner Join AR         On M.Cd_AR  = AR.Cd_AR

				Left Join ARARMisura  On AR.Cd_AR = ARARMisura.Cd_AR And ARARMisura.DefaultMisura = 1



			ENDTEXT



			xSqlExec(cStmt, 'Materiali')



		Endif



		If Reccount('Materiali') > 0



			Local nId_DoDB, nRec, nRow, nQta, nFattUM1



			** A) Per prima cosa se esiste elimino la distinta custom associata alla riga documento



			If lExistDoDB



				** Se sto cancellando una distinta che esisteva sul server posso contare sul server che agisce in due modi:

				** 1) attraverso il trigger in DoRig, che provvede a cancellare la distinta solo se non è utilizzata da

				**    nessun'altra riga di altri documenti

				** 2) attraverso le relazioni delle tavole DoDB, DoDBAttivita, DoDBMateriale che provvedono attraverso i

				**    cascade delete a propagare correttamente le modifiche alle tavole



				nId_DoDB = DoRig.Id_DoDB

				Delete In DoDB

				Tableupdate(0, .F., 'DoDB')



				Select DoDBAttivita

				Scan For Id_DoDB = nId_DoDB

					Delete

					Tableupdate(0, .F., 'DoDBAttivita')

				Endscan



				Select DoDBMateriale

				Scan For Id_DoDB = nId_DoDB

					Delete

					Tableupdate(0, .F., 'DoDBMateriale')

				Endscan



				Replace Id_DoDB With Null In DoRig



			Endif



			** B) Adesso procedo a generare le righe d'ordine a partire dalla lista materiali; il

			**		parametro nConvertType indica come si desidera che avvenga la generazione



			Select DoRig



			nRec 		= Recno()

			nRow 		= DoRig.Riga

			nQta 		= DoRig.Qta

			nFattUM1 = DoRig.FattoreToUM1



			Wait Thisform.TX_(,'F2803A50-3A7F-4DED-8C69-98C0E430B984', 'Conversione in Lista Materiali in corso ...') Windows Nowait

			Thisform.LockScreen = .T.



			With Thisform.PF.pgGenerale.PF.pgRighe.Cnt.Grid



				** Tolgo il fuoco dalla Grid in modo che l'eventuale Valid si scateni e tutto si normalizzi

				Thisform.Title_Bar.SetFocus()



				** Salvo la data consegna del padre

				tDataConsegna = DoRig.DataConsegna



				** Rinumero le righe successive

				Replace Riga With Riga + Reccount('Materiali') For Riga > nRow In DoRig



				Select Materiali

				Scan

					.RowAppend()

					nRow = nRow + 1



					nOldCheckFor = .ColCd_AR.stdText1.CheckFor

					.ColCd_AR.stdText1.CheckFor = 0

					.ColCd_AR.stdText1.SetValue(Materiali.Cd_AR)

					.ColCd_AR.stdText1.CheckFor = nOldCheckFor

					If !.ColCd_AR.stdText1.ControllaStato()

						.ColCd_AR.stdText1.SetValue('')

					Endif



					If IsEmpty(DoRig.DataConsegna)

						Replace DataConsegna With tDataConsegna In DoRig

					Endif



					** Nel caso standard le nuove righe vengono create come righe standard

					** mentre negli altri casi vengono create come righe di tipo 'C'



					Replace																								;

						Riga 			 With nRow,                     											;

						Cd_ARMisura	 With Materiali.Cd_ARMisura,												;

						FattoreToUM1 With 1.00																		;

						Qta			 With Round(Materiali.Consumo * nQta * nFattUM1, nDecimaliQta)	;

						QtaEvadibile With Qta,																		;

						Descrizione	 With Materiali.Descrizione												;

						TipoPC		 With Iif(Inlist(nConvertType, 2, 3), 'C', '')						;

						In DoRig



					.Parent.SetDoRig_Prezzo(DoRig.Qta, 0)

					.Parent.SetDoRig_Formulae()

					.Parent.SetDoRig_PostFormulae()

				Endscan



				** SAS 4359 ** nelle righe dei componenti esplosi non va conteggiata la provvigione (c'è già nel padre)

				Replace All Valprovvigione_1 	with 0	, 	;

				 				Valprovvigione_2 	with 0	, 	;

								FattoreProvv_1 	with 0	, 	;

								FattoreProvv_2 	with 0	, 	;

								ProvvigioneRiga_1 with ''	, 	;

								ProvvigioneRiga_2 with '' 		;

						  For TipoPC = 'C'						;

						  In DoRig

				** SAS 4359 **



				Select DoRig

				Locate Record nRec



				** Nel caso standard la vecchia riga del padre diventa una riga descrittiva

				** mentre negli altri casi la vecchia riga rimane come riga di tipo 'P';  è

				** poi calcolato il nuovo prezzo totale del padre se è stato richiesto

				Do Case

					Case nConvertType == 1

						Local cDescr

						cDescr = ' (' + Transform(DoRig.Qta) + ' ' + RTRIM(DoRig.Cd_ArMisura) + ' composti da:)'

						cDescr = Left(RTrim(DoRig.Descrizione), 80 - Len(cDescr)) + cDescr 

						Replace Cd_AR With Null, Descrizione WITH cDescr, Qta With 1, QtaEvadibile With 1, PrezzoUnitarioV With 0 In DoRig

					Case Inlist(nConvertType, 2, 3)

						Replace TipoPC With 'P' In DoRig

				Endcase

				.Parent.SetDoRig_Formulae()

				.Parent.SetDoRig_PostFormulae()



				** Riporto il fuoco sulla Grid in modo che si evidenzi l'eventuale padre esploso

				.Refresh()

				.SetFocus()



			Endwith



			Wait Clear

			Thisform.LockScreen = .F.



		Endif

		Use In ('Materiali')



		Exit

	Enddo

	Select (nOldWA)



Endif



ENDPROC

PROCEDURE dobitmask_access



** diversamente dalle altre form relative ai documenti (repo, sel, cmd) cge vengono parametrizzate

** con un parametro passato a runtime (cui accede anche il DE per configurarsi opportunamente), le

** fedi vengono subclassate, il paramtro è cablato a design-time nel DE, e lì questo metodo deve

** andare a prenderlo (si ricordi che DE + Elenco vengon istanziati anche dalla form Main senza fedi

** di supporto)



Return This.De.DoBitMask



ENDPROC

PROCEDURE cmddodbedit

Lparameters oParentForm, lQuerySupported



Local lRet



lRet = Lower(Thisform.PF.pgGenerale.PF.CurrentPage.Name) == 'pgrighe'	And ;

		 !Eof('DoRig') And ;

		 !IsEmpty(DoRig.Cd_AR)

		 

If lQuerySupported

	Return lRet

Endif



If IsEmpty(DoRig.Cd_AR)

	xMessageBox(Thisform.TB_(,'D8D00615-8636-4FDD-9F7B-8E79B0E84C17', 'Non è possibile definire una Distinta Custom per una riga descrittiva !!'), MB_ICONSTOP)

	Return	

EndIf



If xSqlExec2Var("Select Fittizio From AR Where Cd_AR = " + FormatC4Spt(DoRig.Cd_AR))

	xMessageBox(Thisform.TB_(,'375CB15F-E9C0-44CC-BBCD-78E8767ED064', 'Non è possibile definire una Distinta Custom per un Articolo Fittizio !!'), MB_ICONSTOP)

	Return	

EndIf



*****************************



Local lShowMode, oRecDoTes, oRecDoRig

Local nOldWA, oCtl, oDriver, lRet



nOldWA = Select(0)



** Caricamento progressivo delle distinte documento; lo faccio qui perchè passo sempre qui

** in tutti i casi sia di show che di edit, da qualunque parte parta il comando

Thisform.DE.DoDB         .Requery('Id_DoDB = ' + Format4Spt(DoRig.Id_DoDB),, .T.)

Thisform.DE.DoDBAttivita .Requery('Id_DoDB = ' + Format4Spt(DoRig.Id_DoDB),, .T.)

Thisform.DE.DoDBMateriale.Requery('Id_DoDB = ' + Format4Spt(DoRig.Id_DoDB),, .T.)



** Se il metodo è lanciato dalla toolbar non viene passato il parametro oParentForm

oParentForm = Iif(Vartype(oParentForm) == 'O', oParentForm, Thisform)

lShowMode	= (Thisform.Mode == FEDIMODE_SHOW)



** Anche se DoRig e DoTes sono già posizionate correttamente si preferisce passare i due oggetti

** oRecDoTes e oRecDoRig come parametri in modo da far lavorare la form DoDBEdit solo sulle tre

** tavole DoDBxxx coinvolte



** Attualmente vengono modificati dalla form soltanto i seguenti parametri:

** 1) oRecDoRig.Id_DoDB

** 2) oRecDoRig.PrezzoUnitarioV



Select DoTes

Scatter Memo Name oRecDoTes

Select DoRig

Scatter Memo Name oRecDoRig



oDriver = NewObjectWCR0('DoDBRunner', 'Forms\ADB_Tools.vcx')

lRet = oDriver.RunDoDBEdit(oParentForm, oRecDoTes, oRecDoRig, lShowMode)

If lRet

	If !lShowMode

		If oRecDoRig.DBModified

			Replace Id_DoDB With oRecDoRig.Id_DoDB In DoRig					

		EndIf

		If oRecDoRig.PrezzoModified

			If oParentForm == Thisform		&&--> La form parent è la Fedi

				oCtl = oParentForm.PF.pgGenerale.PF.pgRighe.cnt.Grid.ColPrezzoUnitarioV.Text1

			Else									&&--> La form parent è la Detail

				oCtl = oParentForm.PF.pgGenerale.txtPrezzoUnitarioV.Field

			EndIf

			oCtl.SetValue(oRecDoRig.PrezzoUnitarioV)

			oCtl.Refresh()

		EndIf

	EndIf

Endif



Select(nOldWA)





ENDPROC

PROCEDURE cmddodbnewdup

Local nWA



nWA  = Select(0)



Select DoRig

Scan For !IsEmpty(Id_DoDB)

	Thisform.DuplicateCustomDB(DoRig.Id_DoDB)

EndScan



Select (nWA)



ENDPROC

PROCEDURE cmdsplitta

Lparameters lQuerySupported



Local lRet



lRet = ThisForm.Mode != FEDIMODE_SHOW												And ;	

		 Lower(Thisform.PF.pgGenerale.PF.CurrentPage.Name) == 'pgrighe'	And ;

		 !Eof('DoRig') 																	And ;

		 !IsEmpty(DoRig.Cd_AR)															And ;

		 DoRig.QtaEvadibile != 0														And ;

		 DoRig.Qta = DoRig.QtaEvadibile



If lQuerySupported

	Return lRet

Endif



If lRet

	Local nOldWA, nRec, nRow, oRec, oGrid, oForm, oControl

	Local nQta1, nQta2, nQtaEvasa1, nQtaEvasa2



	nOldWa = Select(0)

	

	oGrid    = Thisform.PF.pgGenerale.PF.pgRighe.Cnt.Grid

	oControl = Thisform.GetActiveControl(.T.)



	Select DoRig

	nRec = Recno()

	nRow = DoRig.Riga

	

	** Estraggo una copia della riga in fase di splitting

	Scatter Memo Name oRec		

	

	** In ingresso oRec contiene tutti i dati della riga da splittare, e la form non ne modifica

	** alcun valore; in uscita nQta è la quantità da splittare (se != 0)

	nQta2 = 0

	oForm = RunGeneric('Fedi_DocCommon', This, 'DoRigSplitter', oRec)

	If Vartype(oForm) = 'O'

		oForm.Show(1)

		nQta2 = oForm.nQta && quantità della seconda riga

		oForm.Release()

	EndIf

	

	If nQta2 != 0 And nQta2 != DoRig.Qta

		Select DoRig

		

		nQta1 = DoRig.Qta - nQta2

		nQtaEvasa1 =  xRound(DoRig.QtaEvasa / DoRig.Qta * nQta1, oApp.Preferenza.DecimaliQta)

		nQtaEvasa2 = DoRig.QtaEvasa - nQtaEvasa1



		** Aggiorno la Qta e la QtaEvadibile della riga in fase di splitting, nonchè (e solamente) il prezzo totale

		Replace													;

			Qta			 	With nQta1				;

			QtaEvadibile 	With nQta1	;

			QtaEvasa	 		With Iif(!IsEmpty(DoRig.Id_DoRig_Evade), nQtaEvasa1, 0)							;

		In DoRig



		** Il controllo con il fuoco ricorda il valore che aveva all'ingresso e lo confronta con il valore

		** attuale per scatenare OnValueChange; se per caso mi trovavo sulla colonna Qta o QtaEvadibile la

		** modifica fatta qui sopra provoca al primo TAB lo scatenarsi dell'OnValueChange, cosa che voglio

		** assolutamente evitare; per questo motivo con un SetFocus resetto le condizioni del controllo al

		** valore corrente

		oControl.SetFocus()			



		** scateno l'OnValueChange per usufruire della catena di controlli/impostazioni associati

		oGrid.ColQta.stdText1.SetValue(nQta1, .T.)



		** Rinumero le righe successive alla riga in fase di splitting

		Replace Riga With Riga + 1 For Riga > nRow In DoRig

		

		** Aggiungo una riga vuota e sistemo il suo numero d'ordine

		oGrid.RowAppend()

		

		oRec.Id_DoRig = 0 && indica una riga nuova

		oRec.Riga = nRow + 1		



		** Sistemo la Qta e la QtaEvadibile della nuova riga da creare

		oRec.Qta          = nQta2

		oRec.QtaEvadibile = nQta2

		oRec.QtaEvasa 		= nQtaEvasa2



		** Popolo la nuova riga generata, nonchè (e solamente) il prezzo totale

		Select DoRig

		Gather Name oRec Memo	



		** duplicazione distinta se è necessario

		If !IsEmpty(DoRig.Id_DoRig_Evade)

			xSqlExec("Select Id_DODB From DoRig Where Id_DoRig = " + Format4Spt(DoRig.Id_DoRig_Evade), "Tmp_IdDODB")

			If IsEmpty(Tmp_IdDODB.Id_DODB) 

				If !IsEmpty(DoRig.Id_DODB)

					Thisform.DuplicateCustomDB(DoRig.Id_DODB, .T.)

				Endif 

			Else 

				If !SafeCompare(Id_DODB, Tmp_IdDODB.Id_DODB)

					Replace Id_DODB With Tmp_IdDODB.Id_DODB In DoRig

				Endif 

			Endif

		Else

			If !IsEmpty(DoRig.Id_DODB)

				Thisform.DuplicateCustomDB(DoRig.Id_DODB, .T.)

			Endif

		Endif	

		

		** scateno l'OnValueChange per usufruire della catena di controlli/impostazioni associati

		Select DoRig

		oGrid.ColQta.stdText1.SetValue(nQta2, .T.)

		

		** Mi posiziono sulla riga in fase di splitting e rinfresco la griglia

		Select DoRig

		Locate Record nRec

		

		oGrid.Refresh()

		

	EndIf



	Select (nOldWA)	

EndIf

ENDPROC

PROCEDURE douihonor

If !InArtel() Or !Used('DoUiCfg') Or Eof('DoUiCfg')

	Return

EndIf



If !DoUiCfg.ValutaCambio		

	Thisform.PF.pgGenerale.txtCd_VL.SetAll('Visible', .F.)

	Thisform.PF.pgGenerale.txtCambio.SetAll('Visible', .F.)

	Thisform.PF.pgElenco.Elenco.Grid.ColCd_VL.Visible = .F.

	Thisform.PF.pgElenco.Elenco.Grid.ColCambio.Visible = .F.

	Thisform.PF.pgElenco.Elenco.Grid.ColAccontoV.Visible = .F.

	Thisform.PF.pgElenco.Elenco.Grid.ColAbbuonoV.Visible = .F.

	Thisform.PF.pgElenco.Elenco.Grid.ColTotdocumentoV.Visible = .F.

EndIf



Local oDocPF		&& Pageframe interno sulla pagina generale della fedi_doc



oDocPF = Thisform.PF.pgGenerale.PF



If !DoUiCfg.PaginaTesta

	oDocPF.pgGenerale.Enabled = .F.

	oDocPF.pgGenerale.Caption = ''

	oDocPF.pgGenerale.PageOrder = oDocPF.PageCount

EndIf



If !DoUiCfg.PaginaPiede

	oDocPF.pgPiede.Enabled = .F.

	oDocPF.pgPiede.Caption = ''

	oDocPF.pgPiede.PageOrder = oDocPF.PageCount

EndIf



If !DoUiCfg.PaginaTotali

	oDocPF.pgTotali.Enabled = .F.

	oDocPF.pgTotali.Caption = ''

	oDocPF.pgTotali.PageOrder = oDocPF.PageCount

EndIf



If !DoUiCfg.PaginaEvasioni

	oDocPF.pgEvasioni.Enabled = .F.

	oDocPF.pgEvasioni.Caption = ''

	oDocPF.pgEvasioni.PageOrder = oDocPF.PageCount

EndIf



If !DoUiCfg.PaginaModuli

	oDocPF.pgModuli.Enabled = .F.

	oDocPF.pgModuli.Caption = ''

	oDocPF.pgModuli.PageOrder = oDocPF.PageCount

EndIf



**	PiedeDatiDDT					oDocPF.pgPiede.cnt.cntDDT

**										oDocPF.pgPiede.cnt.cntDDT.txtTrasporto

**										oDocPF.pgPiede.cnt.cntDDT.txtVettore1

**										oDocPF.pgPiede.cnt.cntDDT.txtVettore2

**										oDocPF.pgPiede.cnt.cntDDT.txtSpedizione

**										oDocPF.pgPiede.cnt.cntDDT.txtPorto

**										oDocPF.pgPiede.cnt.cntDDT.txtAspettobeni

**										oDocPF.pgPiede.cnt.cntDDT.txtPesoLordo

**										oDocPF.pgPiede.cnt.cntDDT.txtPesoNetto

**										oDocPF.pgPiede.cnt.cntDDT.txtVolume

**										oDocPF.pgPiede.cnt.cntDDT.txtColli				

**										

**	PiedeDatiFattura				oDocPF.pgPiede.cnt.cntFattura

**										oDocPF.pgPiede.cnt.cntFattura.Grid

**										oDocPF.pgPiede.cnt.cntFattura.txtAcconto

**										oDocPF.pgPiede.cnt.cntFattura.txtAbbuono

**										oDocPF.pgPiede.cnt.cntFattura.chkSpeseBolli

**										

**										

**	RigheDettagli				oDocPF.pgRighe.cnt.Grid.ColDettagli

**	RigheDistinta				oDocPF.pgRighe.cnt.Grid.ColDistinta					DetailForm.PF.pgGenerale.btnDoDB		

**	RigheLotto					oDocPF.pgRighe.cnt.Grid.ColCd_ARLotto					DetailForm.PF.pgGenerale.txtCd_ArLotto

**	RigheCommessa				oDocPF.pgRighe.cnt.Grid.ColCd_DoSottoCommessa		DetailForm.PF.pgGenerale.txtCd_DoSottoCommessa

**	RigheDataConsegna			oDocPF.pgRighe.cnt.Grid.ColDataConsegna				DetailForm.PF.pgGenerale.txtDataConsegna

**	RigheUbicazione			oDocPF.pgRighe.cnt.Grid.ColCd_MGUbicazione_P		DetailForm.PF.pgGenerale.txtCd_MG_P.Field1

**									oDocPF.pgRighe.cnt.Grid.ColCd_MGUbicazione_A		DetailForm.PF.pgGenerale.txtCd_MG_A.Field1

**	RigheMagazzino				oDocPF.pgRighe.cnt.Grid.ColCd_MG_P						DetailForm.PF.pgGenerale.txtCd_MG_P

**									oDocPF.pgRighe.cnt.Grid.ColCd_MG_A						DetailForm.PF.pgGenerale.txtCd_MG_A

**	RigheSconto					oDocPF.pgRighe.cnt.Grid.ColScontoRiga					DetailForm.PF.pgGenerale.txtScontoRiga

**																																DetailForm.PF.pgGenerale.txtScontoAddizionale

**	RigheProvvigione1			oDocPF.pgRighe.cnt.Grid.ColProvvigioneRiga_1		DetailForm.PF.pgGenerale.txtProvvigioneRiga_1

**	RigheProvvigione2			oDocPF.pgRighe.cnt.Grid.ColProvvigioneRiga_2		DetailForm.PF.pgGenerale.txtProvvigioneRiga_2

**	RigheUnitaMisura			oDocPF.pgRighe.cnt.Grid.ColCd_ARMisura				DetailForm.PF.pgGenerale.txtCd_ARMisura

**									oDocPF.pgRighe.cnt.Grid.ColFattoreToUM1				DetailForm.PF.pgGenerale.txtFattoreToUm1



**	RigheCA						oDocPF.pgRighe.cnt.Grid.ColCd_CAVda					DetailForm.PF.pgGenerale.cnt_CA

**									oDocPF.pgRighe.cnt.Grid.ColCd_CACda

**									oDocPF.pgRighe.cnt.Grid.ColCd_CAFormula

**									oDocPF.pgRighe.cnt.Grid.ColCAPartenza

**									oDocPF.pgRighe.cnt.Grid.ColCADurata





ENDPROC

PROCEDURE duplicatecustomdb

Lparameters nId_DODB, lLocale



** Si lavora sul record corrente di DoRig; questo perchè è stata fatta la scelta di 

** lasciare a zero Id_DoRig delle righe nuove e quindi la riga non sarebbe identificabile

** in altro modo (RecNo a parte)



Local nWA, oRec



nWA = Select(0)



If lLocale

	Thisform.DE.DoDB.Requery         ('Id_DoDB = ' + Format4Spt(nId_DoDB),, .T.)

	Thisform.DE.DoDBAttivita.Requery ('Id_DoDB = ' + Format4Spt(nId_DoDB),, .T.)

	Thisform.DE.DoDBMateriale.Requery('Id_DoDB = ' + Format4Spt(nId_DoDB),, .T.)



	Select DODB.* 				From DODB 			 Where 1=0 Into Cursor Dup_DODB 				ReadWrite

	Select DODBAttivita.* 	From DODBAttivita  Where 1=0 Into Cursor Dup_DODBAttivita	ReadWrite

	Select DODBMateriale.* 	From DODBMateriale Where 1=0 Into Cursor Dup_DODBMateriale	ReadWrite

	

	Select DODB

	Scan For DODB.Id_DODB = nId_DODB

		Select DODB		

		Scatter Memo Name oRec

		Select Dup_DODB

		Append Blank 

		Gather Memo Name oRec

	EndScan

	

	Select DODBAttivita

	Scan For DODBAttivita.Id_DODB = nId_DODB

		Select DODBAttivita		

		Scatter Memo Name oRec

		Select Dup_DODBAttivita

		Append Blank 

		Gather Memo Name oRec

	EndScan



	Select DODBMateriale

	Scan For DODBMateriale.Id_DODB = nId_DODB

		Select DODBMateriale		

		Scatter Memo Name oRec

		Select Dup_DODBMateriale

		Append Blank 

		Gather Memo Name oRec

	EndScan

Else

	xSqlExec(Thisform.DE.DODB.BuildRequeryStmt(			 'Id_DODB = ' + Format4Spt(nId_DODB)), 'Dup_DODB')

	xSqlExec(Thisform.DE.DODBAttivita.BuildRequeryStmt( 'Id_DODB = ' + Format4Spt(nId_DODB)), 'Dup_DODBAttivita')

	xSqlExec(Thisform.DE.DODBMateriale.BuildRequeryStmt('Id_DODB = ' + Format4Spt(nId_DODB)), 'Dup_DODBMateriale')

Endif



Local nId_DoDBNew, nId_DoDBOld, nId_DoDBAttivitaNew, nId_DoDBAttivitaOld, nId_DoDBMaterialeNew

Local oRec, nRec



** Duplico DODB

Select Dup_DODB

Scatter Memo Name oRec

Select DODB

Append Blank In DODB

oRec.Id_DODB = Recno('DODB')

Gather Memo Name oRec 

Replace All Id_DODB With oRec.Id_DODB In Dup_DODBAttivita

Replace All Id_DODB With oRec.Id_DODB In Dup_DODBMateriale

Replace     Id_DODB With oRec.Id_DODB In DoRig



** Duplico DODBAttivita

Select Dup_DODBAttivita

Scan

	nRec = Recno('Dup_DODBAttivita')

	nId_DODBAttivitaOld = Dup_DODBAttivita.Id_DODBAttivita

	Scatter Memo Name oRec

	Append Blank In DODBAttivita

	oRec.Id_DODBAttivita = Recno('DODBAttivita')

	Replace Id_DODBAttivita With oRec.Id_DODBAttivita In Dup_DODBAttivita

	Select DODBAttivita

	Gather Memo Name oRec 

	Replace Id_DODBAttivita_Next With oRec.Id_DODBAttivita For Id_DODBAttivita_Next = nId_DODBAttivitaOld In Dup_DODBAttivita

	Replace Id_DODBAttivita With oRec.Id_DODBAttivita For Id_DODBAttivita = nId_DODBAttivitaOld In Dup_DODBMateriale

	Select Dup_DODBAttivita

	Locate Record (nRec)

Endscan

Select Dup_DODBAttivita

Scan

	Replace Id_DODBAttivita_Next With Dup_DODBAttivita.Id_DODBAttivita_Next For Id_DODBAttivita = Dup_DODBAttivita.Id_DODBAttivita In DODBAttivita

Endscan



** Duplico DODBMateriale

Select Dup_DODBMateriale

Scan

	Scatter Memo Name oRec

	Select DODBMateriale

	Append Blank In DODBMateriale

	oRec.Id_DODBMateriale = Recno('DODBMateriale')

	Gather Memo Name oRec 

	Select Dup_DODBMateriale

Endscan



Use In Dup_DODB

Use In Dup_DODBAttivita

Use In Dup_DODBMateriale



Select (nWA)





ENDPROC

PROCEDURE checknextnumdoc

If DoTes.Esecutivo = .F.

	** Se il documento che sto registrando non sarà esecutivo

	Return .T.

EndIf



If Val(Left(DoTes.NumeroDoc,6)) > 0    		

	** L'operatore ha messo un numero documento

	Return .T.

EndIf



Local oRec



oRec = This.PF.pgGenerale.txtCd_Do.Field.FKRecord

oRec.Contabile = Iif(oApp.LicInfo.CG_Main Or CG_Export(), oRec.Contabile, .F.)



Return CheckNextNumDoc(oRec, DoTes.DataDoc)

ENDPROC

PROCEDURE rr_setdefaults

** L'alias per default è DORIG ma potrebbe essere necessario farlo anche per dorigspesa

Lparameters cAlias



Local oDef



** ----- LICADAPTER

If !oApp.LicInfo.CG_Main

	Return .F.

EndIf



cAlias = xDefault(cAlias, 'DORig')

oDef 	 = RR_GetDefaults_DO(DOTes.Cd_Do, &cAlias..Cd_CGConto, DOTes.DataDoc)



** Se il conto è vuoto lo prendo dalle impostazioni

If oDef.RR_Enabled And IsEmpty(oDef.RR_Cd_CGConto)

	oDef.RR_Cd_CGConto = RR_GetConto(Null, DOTes.DataDoc, &cAlias..RR_DataInizio, &cAlias..RR_DataFine, Null, Null)

EndIf



Replace ;

	RR_Enabled		With oDef.RR_Enabled		;

	RR_Cd_CGConto 	With oDef.RR_Cd_CGConto	;

	RR_DataInizio 	With oDef.RR_DataInizio ;

	RR_DataFine   	With oDef.RR_DataFine 	;

	In (cAlias)



RR_ValidateFields(DOTes.DataDoc, oDef.RR_DataInizio, oDef.RR_DataFine)

ENDPROC

PROCEDURE rr_validate

Lparameters cAlias



Local oDO, oWA

Local cMsg



cAlias	= xDefault(cAlias, 'DORig')

oDO 		= ThisForm.PF.pgGenerale.txtCd_DO.Field.FKRecord

oWA		= SelectWA(cAlias)



** Controllo la validità delle date di inizio/fine RR

** ----- LICADAPTER

If oDO.RR_Enabled And oApp.LicInfo.CG_Main



	** Controllo se esistono righe senza dati per RR (warning)

	Locate For ;

		RR_Enabled And ;

		(IsEmpty(RR_DataInizio) Or IsEmpty(RR_DataFine) Or IsEmpty(RR_Cd_CGConto)) And ;

		!(IsEmpty(RR_DataInizio) And IsEmpty(RR_DataFine) And IsEmpty(RR_Cd_CGConto))



	If Found(cAlias)

		If Lower(cAlias) == 'dorigspesa'

			cMsg = Thisform.TB_(,'45984293-4829-4582-B286-F1BAD4E5FB06', "Il movimento presenta righe spesa senza tutti i dati necessari per l'elaborazione di ratei e risconti." + CRLF + "Proseguo?")

		Else

			cMsg = Thisform.TB_(,'91ABBE28-64DF-46EE-B0B9-5A1FD5DA217C', "Il movimento presenta righe senza tutti i dati necessari per l'elaborazione di ratei e risconti." + CRLF + "Proseguo?")

		EndIf 

	

		If xMessageBox(cMsg, MB_ICONEXCLAMATION + MB_YESNO + MB_DEFBUTTON2) = IDNO

			Return .F.

		EndIf

	EndIf



	Scan For RR_Enabled 

	**And !IsEmpty(RR_Cd_CGConto)

		If !RR_ValidateFields(DOTes.DataDoc, &cAlias..RR_DataInizio, &cAlias..RR_DataFine, .T.)



			If Lower(cAlias) == 'dorigspesa'

				cMsg = Thisform.TB_(,'F6A999D4-68BC-457C-974D-DAB7596AFBCC', "Alcune righe spesa presentano date di competenza del periodo non valide per ratei/risconti.")

			Else

				cMsg = Thisform.TB_(,'1D0B2821-C3FE-4260-B15A-68E9CCF04B0D', "Alcune righe presentano date di competenza del periodo non valide per ratei/risconti.")

			EndIf 

			xMessageBox(cMsg)

			Return .F.

		EndIf

	EndScan

EndIf

ENDPROC

PROCEDURE rr_reload

Lparameters cAlias



Local oWA, oDO, oCGConto



cAlias	= xDefault(cAlias, 'DORig')

oWA		= SelectWA(cAlias)

oDO		= ThisForm.PF.pgGenerale.txtCd_DO.Field.FKRecord



If oDO.RR_Enabled

	Scan For RR_enabled

		This.RR_SetDefaults(cAlias)

	EndScan

EndIf



Release oWa



This.RR_RefreshFields(ThisForm.PF.pgGenerale.PF.PGRighe.Cnt.Grid.ColCd_CGConto.Controls(2))



ENDPROC

PROCEDURE rr_refreshfields

Lparameters oControl



** Richiamato dal dettaglio

If Atc('fedi_doc', Sys(1272, oControl)) != 0 And Atc('detail', Sys(1272, oControl)) != 0

	oControl.Parent.Parent.Cnt_RR.Refresh()

Else

	** Funziona sia per la grid di Dorig che dorgispesa a patto che i controls si chiamino allo stesso modo (Text1)

	oControl.Parent.Parent.ColRR_Cd_CGConto.Text1.Refresh()

	oControl.Parent.Parent.ColRR_DataInizio.Text1.Refresh()

	oControl.Parent.Parent.ColRR_DataFine.Text1.Refresh()

	** oControl.Parent.Parent.ColRR_Cd_CGConto_Desc.StdText1.Refresh()

EndIf



ENDPROC

PROCEDURE getdatapag

Lparameters lQuerySupported



If lQuerySupported

	Return !IsEmpty(DOTes.DataDoc) And !IsEmpty(DOTes.Cd_PG)

EndIf



Return SC_GetDataPag(DOTes.DataDoc, DOTes.Cd_PG)

ENDPROC

PROCEDURE ra_previdenza_check

**	0 : Context Menu Action

**	1 : Final Check



Lparameters lQueryMode, cCd_CGConto, oMenu



Local oRA, oSubMenu



cCd_CGConto = xDefault(cCd_CGConto, DoRig.Cd_CGConto)



** Defect 250202 Aggiunto parametro finale DoRigSpesa

oRA 			= RA_Previdenza_DO('DoRig', DoTes.Cd_CF, DoTes.Cd_DO, DoTes.Cambio, 'DoRigSpesa')



DO Case



	Case	lQueryMode = 0 And oRa.Error_Code >= 0 And Vartype(oMenu) == 'O' And ;

			xSqlExists('CGConto', "Cd_CGConto = '" + cCd_CGConto + "' And RATipo IN (2, 4)", , .T.)



		oSubMenu = NewObject0('ShortcutMenu', 'Libs\_BaseOthCtrl.vcx')

		oSubMenu.AddMenuBar(Thisform.TM_(,"B04FD161-67A7-405C-B18E-C576C7BFFCBE", "Imponibile: ")			, , 'Key Alt+0, "' + Transform(oRa.Tot_Imponibile, '###,###,###.##') + ' €"',  1)

		oSubMenu.AddMenuBar(Thisform.TM_(,"E006EC99-E5CF-4D52-B2DF-DECAF9E36263", "% previdenza: ")		, , 'Key Alt+0, "' + Transform(oRa.Perc, 			 	'###.##'		  	 ) + ' €"',  2)

		oSubMenu.AddMenuBar(Thisform.TM_(,"2DC0954B-77D7-4E67-8972-EB5AE43366D3", "Importo calcolato: ") , , 'Key Alt+0, "' + Transform(oRa.Importo, 		 	'###,###,###.##') + ' €"',  3) 

		oSubMenu.AddMenuBar(Thisform.TM_(,"C00E37B9-5647-4DEB-9763-EAED1BA0FADA", "Importo dichiarato: "), , 'Key Alt+0, "' + Transform(oRa.Tot_Importo, 	'###,###,###.##') + ' €"',  4)

		oSubMenu.AddMenuBar('\-')

		oSubMenu.AddMenuBar(Thisform.TM_(,"53E4BF54-E373-4D41-992B-70C0DAB945E4", "Differenza: ")			, , 'Key Alt+0, "' + Transform(oRa.Delta, 			'###,###,###.##') + ' €"', 10)

			

		oMenu.AddMenuBar(Thisform.TM_(,"D79C7ADE-9B2F-4328-99BC-3FA9D893DA97", "\<Dati previdenza ..."), oSubMenu , , MB_EDIT_SRCHSPEC2, , .F., , "Images\MnuImages\Info.bmp")

	

	Case lQueryMode = 1 And oRa.Error_Code > 0



		Local cText

		

		Text To cText NoShow PreText 1+2

			L'importo indicato per la cassa previdenza non corrisponde a quello

			calcolato in base all'imponibile a ritenuta e la percentuale

			dichiarata nell'anagrafica del fornitore %1!.



			Imponibile: € %2!

			% previdenza: € %3!

			Importo calcolato: € %4!

			Importo dichiarato: € %5!

			Differenza: € %6!

			

			Continuo?

		EndText 

		

		Return xMessagebox(Thisform.TB_(,'0F771A96-0A02-4A0D-A045-FED3115B7B7B', cText,	Alltrim(DoTes.Cd_CF), 												;

																										Alltrim(Tran(oRa.Tot_Imponibile, '###,###,###.##'	)), 	;

																										Alltrim(Tran(oRa.Perc, 				'###.##'				)),	;

																										Alltrim(Tran(oRa.Importo, 			'###,###,###.##'	)),	;

																										Alltrim(Tran(oRa.Tot_Importo, 	'###,###,###.##'	)),	;

																										Alltrim(Tran(oRa.Delta, 			'###,###,###.##'	))) ,	;					

					MB_IQYNDB2) = IDYES

		

EndCase



Return .T.

ENDPROC

PROCEDURE cmddopush

Local lShowMode, oForm, nOldWA, lRet



oForm = RunGeneric('Fedi_DocCommon', ThisForm, 'DoPush', Thisform.DoBitMask , DoTes.Id_DoTes)



IF VarType(oForm) == 'O'

	oForm.Show(1)

EndIf



This.De.DoTes.RequeryCurrent()

This.Toolbar.Buttons('DOPUSH').Enabled = (DoTes.RigheEvadibili > 0)

This.Refresh()



ENDPROC

PROCEDURE ca_setdefaults

Local cDOAlias, cCd_CF, oWA



cDOAlias = ThisForm.PF.pgGenerale.txtCd_DO.Field.FKAlias

cCd_CF	= Iif(IsEmpty(Substr(Evl(DOTes.Cd_CF, ''), 2)), Null, DOTes.Cd_CF)



** ----- LICADAPTER

If &cDOAlias..CAEnabled And oApp.LicInfo.CA_Main



   oWA = SelectWA('DoRig')



   Scan For !IsEmpty(Cd_CGConto)



      oRec = DoRig_Defaults_CA_2Obj(DoTes.Cd_DO, cCd_CF, DoTes.Cd_CFDest, DoRig.Cd_Ar, DoRig.Cd_CGConto)



      Replace ;

      	Cd_CAVda 		With oRec.Cd_CAVda, ;

         Cd_CACda 		With oRec.Cd_CACda, ;

         Cd_CAFormula 	With oRec.Cd_CAFormula, ;

         CAPartenza 		With oRec.CAPartenza, ;

         CADurata 		With oRec.CADurata ;

         In DoRig

   EndScan



   Release oWA

   

   oWA = SelectWA('DoRigSpesa')



   Scan For !IsEmpty(Cd_CGConto)



      oRec = DoRig_Defaults_CA_2Obj(DoTes.Cd_DO, cCd_CF, DoTes.Cd_CFDest, Null, DoRigSpesa.Cd_CGConto)



      Replace 	;

      	Cd_CAVda 		With oRec.Cd_CAVda, ;

         Cd_CACda 		With oRec.Cd_CACda, ;

         Cd_CAFormula 	With oRec.Cd_CAFormula, ;

         CAPartenza 		With oRec.CAPartenza, ;

         CADurata 		With oRec.CADurata ;

         In DoRigSpesa

   EndScan



   With ThisForm.PF.pgGenerale.PF.PGRighe.Cnt.Grid

      .ColCd_CAVda.Refresh()

      .ColCd_CACda.Refresh()

      .ColCd_CAFormula.Refresh()

      .ColCAPartenza.Refresh()

      .ColCADurata.Refresh()

	EndWith

	

	With ThisForm.PF.pgGenerale.PF.pgPiede.Cnt.CntFattura.Grid

      .ColCd_CAVda.Refresh()

      .ColCd_CACda.Refresh()

      .ColCd_CAFormula.Refresh()

      .ColCAPartenza.Refresh()

      .ColCADurata.Refresh()

   EndWith

   

EndIf

ENDPROC

PROCEDURE calcarrotondamento

Lparameters m.TotaleV, m.ArrotondamentoN, m.ArrotondamentoC



Return Fedi_Doc_CalcArrotondamento(m.TotaleV, m.ArrotondamentoN, m.ArrotondamentoC)



ENDPROC

PROCEDURE getspesebolliflag

Local lFromCF, lFromDO, lApply



If Empty(Dotes.Cd_CF) Or Empty(Dotes.Cd_DO)

	Return .F.

EndIf



lFromCF 	= (xSqlExec2Var("Select SpeseBolli From CF Where Cd_CF = " + FormatC4Spt(DoTes.Cd_CF)))

lFromDO 	= (Impostazione.Imp_DOEsente_ApplicaNC Or xSqlExec2Var("Select TipoDocumento From DO Where Cd_DO = " + FormatC4Spt(DoTes.Cd_Do)) != 'N')

lApply	= !(Thisform.Mode = FEDIMODE_EDIT And xSQLexec2bit(Textmerge('Exists(Select * From CGmovT Where Id_Dotes = <<DoTes.Id_DoTes>> And ProvvisorioDaDocumento = 0)')))



** Se il documento è in EDIT + CONTABLIZZATO non applico, si dovrebbe riapplicare alla variazione del totale esente ma in quel caso

** cambiaerebbero altre entità che richiederebbero la registrazione del documento.



Return lFromCF And lFromDO And lApply

ENDPROC

PROCEDURE controllofido

Lparameters oDoTotali



Local nSegno, nCurDoc, nRec, nDifferenza

Local oDoRec, oCF, oFormFido 



oDoRec = This.PF.pgGenerale.txtCd_Do.Field.FKRecord	

** fatturazione

oCF    = ThisForm.PF.pgGenerale.PF.pgGenerale.txtCF_Fatt.Field.FKRecord

** intestatario (eventualmente)

oCF	 = Iif(!IsEmpty(oCF.Cd_CF), oCF, ThisForm.PF.pgGenerale.txtCd_CF.Field.FKRecord)



If oDoRec.UIchkFido And oDoRec.UIchkFidoFin And oCF.Fido != 0



	nSegno = IIF(oDorec.TipoDocumento = 'N', -1, 1)



	If InList(oDorec.TipoDocumento, 'F', 'A', 'N')

		** Documenti IVA (considero il Netto a Pagare)

		nCurDoc = oDoTotali.TotAPagareE

	Else

		** Documenti non IVA (considero la somma dei valori residui delle righe merce e spese)

		

		Local nTotR, nTotS, nCambio

		nCambio = NEvl(DoTes.Cambio, 1)

		

		If Bittest(oApp.Preferenza.CFEsposizione_Flag, 0)		&& 0x0001 -> considera l'iva 

			nTotR = 0

			nTotS = 0



			** Estraggo in un cursore la tabella Aliquota

			xSqlExec('Select Cd_Aliquota, Aliquota  From Aliquota', '_Aliq')

			Index On Cd_Aliquota Tag Cd_Aliq Collate "Machine"



			** Verifico se il cliente è in esenzione

			** #DICHINT#

			** Local cCd_AliquotaEs

			** cCd_AliquotaEs = xSqlExec2Var(Textmerge("Select Cd_Aliquota From CFEsenzione Where ?<<Iif(DoTes.CliFor == 'C', 'DoTes.DataDoc', Iif(!IsEmpty(DoTes.DataDocRif), 'DoTes.DataDocRif', 'DoTes.DataDoc'))>> Between DataInizio And DataFine And Cd_CF = ?DoTes.Cd_Cf"))

			

			Select DoRig

			Scan For Omaggio = 1 And TipoPC != 'C'

				** #DICHINT#

				** Seek NEvl(cCd_AliquotaEs, DoRig.Cd_Aliquota) In _Aliq

				Seek DoRig.Cd_Aliquota_R In _Aliq

				nTotR = nTotR + xRound((DoRig.PrezzoTotaleV / Evl(DoRig.Qta, 1) * DoRig.QtaEvadibile) * ((100 + _Aliq.Aliquota)/100) / nCambio, 2)

			EndScan 

		

			Select DoRigSpesa

			Scan

				** #DICHINT#

				** Seek NEvl(cCd_AliquotaEs, DoRigSpesa.Cd_Aliquota) In _Aliq

				Seek Iif(!IsEmpty(DoRigSpesa.Cd_Aliquota_R), DoRigSpesa.Cd_Aliquota_R, DoRigSpesa.Cd_Aliquota) In _Aliq

				If DoRigSpesa.ImportoEvadibileV <> 0 And  DoRigSpesa.Perc = 0

					nTotS = nTotS + xRound( DoRigSpesa.ImportoEvadibileV * ((100+_Aliq.Aliquota)/100) / nCambio, 2)					&& Spese in importo

				Else

					nTotS = nTotS + xRound(nTotR * DoRigSpesa.Perc / 100, 2)																		&& Spese in percentuale

				EndIf

			EndScan 



			Use In (Select('_Aliq'))

		Else

			** Non devo considerare l'iva...

			Calculate Sum(Round((DoRig.PrezzoTotaleV / Evl(DoRig.Qta, 1) * DoRig.QtaEvadibile)	/ nCambio, 2)) For Omaggio = 1 And TipoPC != 'C' To nTotR In DoRig	

			Calculate Sum(Round( DoRigSpesa.ImportoEvadibileV 												/ nCambio, 2)) 					 						 To nTotS In DoRigSpesa

		EndIf 

		

		nCurDoc = nTotR + nTotS 

	EndIf 



**	oFormFido = NewObjectWCR7('ControlloFido', 		'Forms\Fedi_DocCommon.vcx', '', oCF.Cd_CF, !oDoRec.UIchkFidoBo, !oDoRec.UIchkFidoOC, nCurDoc * nSegno, oDoRec.UIchkFidoBlk, This.DoBitmask, DoTes.Id_DoTes)

	oFormFido = NewObjectWCR5('ControlloFido_Ahts', 'Forms\Fedi_DocCommon.vcx', '', oCF.Cd_CF, !oDoRec.UIchkFidoBo, !oDoRec.UIchkFidoOC, nCurDoc * nSegno,   											  DoTes.Id_DoTes)



	If Vartype(oFormFido) = 'O'

		nDifferenza = oFormFido.Differenza

		If oDoRec.UIchkFidoVis Or nDifferenza < 0

			oFormFido.Show(1)

			Inkey(0.1, "H")

		EndIf

		oFormFido.Release()		

		If nDifferenza < 0

			If oDoRec.UIchkFidoBlk

				xMessageBox(Thisform.TB_(,'41B910D1-2DA4-4040-9CE1-1A660120BA93', "Emissione Bloccata a causa del superamento del fido!!"), MB_ICONSTOP)

				Return .F.

			Else

				If xMessageBox(Thisform.TB_(,'05D02541-12B5-4389-B0A7-65C0004FCE66', "Il fido è stato superato!! Si vuole proseguire ugualmente ?"), MB_YESNO + MB_ICONQUESTION + MB_DEFBUTTON2) = IDNO

					Return .F.

				Else

					If oDoRec.UIchkFidoBlkE

						xMessageBox(Thisform.TB_(,'03EFAEC7-E409-49F3-9E24-908254CFBE38', 'Evadibilità bloccata a causa del superamento del fido!!'), MB_ICONINFORMATION)

						This.PF.pgGenerale.PF.pgGenerale.cntStato.chkPrelevabile.SetValue(.F.)

					EndIf

				EndIF

			EndIf

		EndIf

	EndIf

EndIf



ENDPROC

PROCEDURE checkivadifferita

** Verifico che in presenza di documento con iva differita le operazioni iva abbiano regime compatibile.

** Devono essere tutte dello stesso tipo: o tutte in regime di cassa o no, altrimenti poi ci sono problemi nell'identiticazione delle operazioni

** con iva x cassa in quanto l'attributo è unico ed in testa al movimento.



Local lWarning, lWarningR, lWarningS, curWA

Local Array aLiq_R[1]

Local Array aLiq_S[1]



lWarning = .f.



** Sarebbe da fare soltanto su movimenti con causale contabile in quanto fatture con valenza iva

** ma per il momento lo teniammo anche sugli altri documenti.

If DOTes.IvaSospesa

	

	curWA = Select(0)

	

	cCd_CGCausale = Cast(Nvl(ThisForm.PF.PgGenerale.txtCd_DO.Field.FKRecord.Cd_CGCausale, '') as C(3))

	

	Select	;

		DORig.Cd_Aliquota_r		as Cd_Aliquota,	;

		cCd_CGCausale				as Cd_CGCausale, ;

		'R'							as TipoRiga		;

	From	;

		DORig		With (Buffering = .T.)		;

	Group by			;

		Cd_Aliquota_r ;

	Union All	;

	Select	;

		DORIgSpesa.Cd_Aliquota_r	as Cd_Aliquota,	;

		cCd_CGCausale					as Cd_CGCausale, ;

		'S'								as TipoRiga		;

	From	;

		DORIgSpesa	With (Buffering = .T.)		;

	Group by			;

		Cd_Aliquota_r ;

	Into Cursor _Aliq ReadWrite

	

	Local cTable

	

	IF CursorToServer('_Aliq', @cTable, , ) > 0 THEN

		

		Text To cStmt NoShow TextMerge

			

			Select

				TipoRiga = T.TipoRiga,



				-- IvaCassa di riga:

				IvaCassa = Coalesce(AL.IvaCassa, CL.IvaCassa, Cast(IsNull((Select Top 1 IvaCassa From CGLiq Where Prevalente = 1), 0) as Bit))



			From

				<<cTable>>		T



				Left Join Aliquota	A	on A.Cd_Aliquota = T.Cd_Aliquota

				Left Join CGLiq		AL on AL.Cd_CGliq = A.Cd_CGLiq



				Left Join CGCausale	C	on C.Cd_CGCausale = T.Cd_CGCausale

				Left Join CGLiq		CL	on CL.Cd_CGliq = C.Cd_CGLiq

			

		EndText

		

		If xSqlExec(cStmt, '_Tmp') > 0 Then

			

			* Controllo righe documento

			Select IvaCassa From _Tmp Where TipoRiga = 'R' Group By IvaCassa Into Array aLiq_R

			lWarningR = (_Tally > 1)

			

			* Controllo righe di spesa

			Select IvaCassa From _Tmp Where TipoRiga = 'S' Group By IvaCassa Into Array aLiq_S

			lWarningS = (_Tally > 1)

			

			Use in '_Tmp'

			

			xSqlExec(Textmerge([Drop Table <<cTable>>]))

			

			lWarning = (lWarningR or lWarningS)

			If lWarning

				cMsg =	[Attenzione: non è possibile salvare documenti che utilizzano aliquote con attività differenti se non presentano lo stesso regime per cassa.] + ;

							CRLF + CRLF + [Verificare la configurazione delle attività indicate nelle aliquote presenti sulle righe ] + ;

							ICase(lWarningR And lWarningS, 'documento/spesa.', lWarningR, 'documento.', lWarningS, 'spesa.', '') + ;

							Iif(!Empty(cCd_CGCausale), [ Se nell'aliquota non è specificata un'attività, sarà considerato quanto parametrizzato nella causale del documento.], '')

			

				xMessageBox(Thisform.TB_(,'72BDB1A4-E56A-4538-8317-70F6C94B193E', cMsg), MB_ICONSTOP)

			EndIf

			

		EndIf

		

	EndIf

	

	Use in '_Aliq'

	

	Select(curWA)

	

EndIf



If lWarning

	Return .F.

EndIf



** In presenza di regime x cassa avverto per l'incongruenza con il tipofattura in reverse charge (tecnicamente non è gestibile ne peremsso dalla normativa)

If DoTes.IvaSospesa And DoTes.Clifor == 'F' And DoTes.TipoFattura != 0 And ;

	xMessageBox(Thisform.TB_(,'931D8986-B3B8-425B-973C-846C50F37DF5', "Attenzione. Le operazioni con inversione contabile non sono interessate dal regime iva per cassa DL 83/12. " + ;

					"L'operazione non potrà essere trattata secondo i criteri dettati dalla norma." + Chr(13) + 'Proseguo ?'), MB_ICONEXCLAMATION + MB_YESNO) = IDNO

	Return .F.

EndIf



Return .T.

ENDPROC

PROCEDURE checknumdocrif

Local cScript, lFound, oDO, cNumRif, cText



** Verifico la presenza di altri documenti con lo stesso numero. Spostato il controllo dal TRG per avere più flex anche in import di COGE.

** Sarebbe meglio presentare l'elenco dei movimenti interessati ma vedremo se in futuro migliorare. Utilizzo il TOP 1 invece dell'exists per ottenere

** almeno il primo dei movimenti nel caso si volesse inserirlo nel msg.



** Utilizzo il valore del text invece che del field in quanto potrei utilizzare il mess di ritorno per esempio nel tooltip del campo senza lasciare il fuoco.

cNumRif         = Alltrim(ThisForm.PF.pgGenerale.PF.pgGenerale.txtNumeroDataRif.Field.Value)

oDO             = ThisForm.PF.pgGenerale.txtCd_DO.Field.FKRecord

cText           = ''



If oDO.Clifor == 'F' And oDo.Contabile And !IsEmpty(cNumRif) And !IsEmpty(DoTes.DataDocRif)



	Text To cScript TextMerge Noshow Flags 1 Pretext 7

		Exists(Select * From CGMovT Where Cd_CF = <<FormatC4SPT(DOTes.Cd_CF)>> And Ltrim(Rtrim(NumRif)) = <<FormatC4SPT(cNumRif)>> And Year(DtRif) = <<FormatN4SPT(Year(DoTes.DataDocRif))>> And TipoMovimento = 'A' And (Id_Dotes Is Null Or Id_Dotes != <<FormatN4SPT(DoTes.Id_DoTes)>>))

	EndText

        

	lFound  = xSQLExec2Bit(cScript)

	cText   = Iif(lFound, Thisform.TB_(,'9A6F1C18-F8C1-4CC4-8E75-3C35FB269CEA', Textmerge("Rilevata presenza di un'altra registrazione con numero di riferimento <<cNumRif>> per l'anno <<Year(DoTes.DataDocRif)>>.")), '')



EndIf



Return cText



**              Text To cScript TextMerge Noshow Flags 1 Pretext 7



**              If Exists(Select * From DoTes  Where Cd_CF = <<FormatC4SPT(DOTes.Cd_CF)>> And Ltrim(Rtrim(NumeroDocRif)) = <<FormatC4SPT(cNumRif)>> And Year(DataDocRif) = <<FormatN4SPT(Year(DoTes.DataDocRif))>> And Clifor = 'F' And Contabile = 1 And Id_DoTes != <<FormatN4SPT(DoTes.Id_DoTes)>>)

**                      Select MessageType = Convert(Int, 1)

**              Else If

**                      Exists(Select * From CGMovT Where Cd_CF = <<FormatC4SPT(DOTes.Cd_CF)>> And Ltrim(Rtrim(NumRif)) = <<FormatC4SPT(cNumRif)>> And Year(DtRif) = <<FormatN4SPT(Year(DoTes.DataDocRif))>> And TipoMovimento = 'A' And (Id_Dotes Is Null Or Id_Dotes != <<FormatN4SPT(DoTes.Id_DoTes)>>))

**                      Select MessageType = Convert(Int, 2)

**              

**              EndText



**              oRec    = xSQLExec2Obj(cScript)

**              cText   = Iif(!IsNull(oRec), Thisform.TB_(,'9A6F1C18-F8C1-4CC4-8E75-3C35FB269CEA', Textmerge("Rilevata presenza di un altro <<Iif(oRec.messageType = 1, 'documento', 'movimento contabile')>> con numero di riferimento <<cNumRif>> per l'anno <<Year(DoTes.DataDocRif)>>.")), '')



ENDPROC

PROCEDURE cmdftexml

Local oForm, oParm, oWA, oDo, oCF



If !Thisform.Fte_Isxml()

	xMessagebox('Dati aggiuntivi non disponibili per la tipologia di documento corrente.')

	Return .F.

EndIf



oWA = SelectWA('DoTes')

Scatter Name oParm Memo 



** Calcolo alcuni campi che servono per regolamentare il funzionamento della form

oParm.Cd_CF_Fatt_R = xDefault(oParm.Cd_CF_Fatt, oParm.Cd_CF)



oDo	= ThisForm.PF.pgGenerale.txtCd_DO.Field.FKRecord

oCF 	= ThisForm.PF.pgGenerale.txtCd_CF.Field.FKRecord



oParm.TipoDocumento 	= Iif(Thisform.Mode = FEDIMODE_SHOW, oParm.TipoDocumento, oDo.TipoDocumento)

oParm.EntePubblico	= Iif(Thisform.Mode = FEDIMODE_SHOW, oParm.EntePubblico,  oCF.EntePubblico)



** Autofattura: verifico che l'id fiscale della ditta cedente sia uguale al cessionario inclusa la SO



AddProperty(oParm, 'Condominio', 		oCF.Condominio)

AddProperty(oParm, 'Autofattura',		Thisform.Fte_Autofattura())

AddProperty(oParm, 'Semplificata',		Thisform.Fte_Semplificata())

AddProperty(oParm, 'oTotali',				This.TotaleDocumento())

AddProperty(oParm, 'oDO',					oDo)



oForm = RunGeneric('Fedi_DocCommon', Thisform, Iif(Vartype(FTEXMLOLD) != 'U' Or !Empty(xGetEnv('FTEXMLOLD')), 'FTEXMLOLD', 'FTEXML'), oParm)



If Vartype(oForm) = 'O'

	oForm.Show(1)

	oForm.oRec.FTE_Xml = NEvl(oForm.oRec.FTE_Xml, '<rows/>')

	If oForm.WasConfirmed And !SafeCompare(DoTes.FTE_Xml, oForm.oRec.FTE_Xml)

		Replace FTE_Xml With oForm.oRec.FTE_Xml In DoTes

	EndIf 

	oForm.Release()

EndIf





ENDPROC

PROCEDURE fte_isxml

**	Debugout "oApp.LicInfo.FatturaElettronica", oApp.LicInfo.FatturaElettronica

**	Debugout "Vartype(This.oFteXml) == 'O'", Vartype(This.oFteXml) == 'O'

**	Debugout "Thisform.Mode = FEDIMODE_SHOW", Thisform.Mode = FEDIMODE_SHOW

**	Debugout "DoTes.TipoDocumento", DoTes.TipoDocumento

**	Debugout "DoTes.FatturaElettronica", DoTes.FatturaElettronica

**	Debugout "DoTes.CodiceIPA", DoTes.CodiceIPA

**	Debugout "Nvl(xSQLExec2Var(Textmerge('Select CN.FatturaElettronica From CN Join DO On CN.Cd_CN = DO.Cd_CN Where DO.Cd_DO = <<FormatC4Spt(DoTes.Cd_DO)>>')), .F.)", Nvl(xSQLExec2Var(Textmerge('Select CN.FatturaElettronica From CN Join DO On CN.Cd_CN = DO.Cd_CN Where DO.Cd_DO = <<FormatC4Spt(DoTes.Cd_DO)>>')), .F.)

**	Debugout "Nvl(xSQLExec2Var(Textmerge('Select TipoDocumento From DO Where Cd_DO = <<FormatC4Spt(DoTes.Cd_DO)>>')), '')", Nvl(xSQLExec2Var(Textmerge('Select TipoDocumento From DO Where Cd_DO = <<FormatC4Spt(DoTes.Cd_DO)>>')), '')

**	Debugout "xSQLExec2Var(Textmerge('Select CodiceIPA From CF Where Cd_CF = <<FormatC4Spt(DoTes.Cd_CF)>>')))", xSQLExec2Var(Textmerge('Select CodiceIPA From CF Where Cd_CF = <<FormatC4Spt(DoTes.Cd_CF)>>'))



Local cCd_CF



cCd_CF = Iif(!IsEmpty(Substr(DOTes.Cd_CF_Fatt, 2)), DOTes.Cd_CF_Fatt, DOTes.Cd_CF)



Do Case 

	Case Bitand(DoTes.DOBitMask, TD_CA_TUTTO_USED) > 0

		Return ;

			oApp.LicInfo.FatturaElettronica And Vartype(This.oFteXml) == 'O' And ;

			Iif(Thisform.Mode = FEDIMODE_SHOW, (DoTes.TipoDocumento == 'O' Or !IsEmpty(DoTes.FTE_Status)), ;

				(Nvl(xSQLExec2Var(Textmerge('Select CN.FatturaElettronica From CN Join DO On CN.Cd_CN = DO.Cd_CN Where DO.Cd_DO = <<FormatC4Spt(DoTes.Cd_DO)>>')), .F.) Or ;

				 Nvl(xSQLExec2Var(Textmerge('Select TipoDocumento From DO Where Cd_DO = <<FormatC4Spt(DoTes.Cd_DO)>>')), '') == 'O') And ;

				 !IsEmpty(xSQLExec2Var(Textmerge("Select Case When EntePubblico = 1 Then CodiceIPA Else CodiceFPR End From CF Where Cd_CF = <<FormatC4Spt(cCd_CF)>>"))))



	Case Bitand(DoTes.DOBitMask, TD_CP_TUTTO_USED) > 0

		Return !IsEmpty(DoTes.FTE_Status) And DoTes.FTE_Status = 'FEF' 



	Otherwise

		Return .F.

EndCase

ENDPROC

PROCEDURE ivamoss_chk

** ----- LICADAPTER

If oApp.LicInfo.IvaMoss



	Local oWA, oCF, lIvaMoss



	oWA 		= SelectWA('DoRig')

	oCF 		= Iif(!ThisForm.PF.pgGenerale.PF.pgGenerale.txtCF_Fatt.Field.Isempty(), ThisForm.PF.pgGenerale.PF.pgGenerale.txtCF_Fatt.Field.FKRecord, ThisForm.PF.pgGenerale.txtCd_CF.Field.FKRecord)

	lIvaMoss	= This.IvaMoss_Set()



	Select DoRig

	Scan

		

		If Dorig.IvaMoss And !lIvaMoss And ;

			xMessageBox(Thisform.TB_(,'90EAC9D7-DC8B-4815-9C1C-D12BF0C87EC5', 'Rilevato codice iva MOSS non permesso alla riga ' + Transform(Dorig.Riga) + '.' + Chr(13) + Chr(13) + ;

																									'Verificare che il cliente <' + Alltrim(oCF.Cd_CF) + '> sia un consumatore finale appartenente ad uno stato membro UE.' + Chr(13) + Chr(13) + ;

																									'Proseguo ?'), MB_ICONEXCLAMATION + MB_YESNO + MB_DEFBUTTON2, oApp.AppName + ' * IVA MOSS *') = IDNO

			Return .F.



		EndIf

		

		** -------- Abilitare per verificare anche la congruenza del tipo bene/servizio

		** If DoRig.IvaMoss And Dorig.TipoBeneServizio = 'B' And ;

		** 	xMessageBox(Thisform.TB_(,'3930C269-D18C-4A3D-AAA7-ADC2727E964E', 'Rilevato codice iva MOSS per operazione non classificata come servizio nella sezione IVA alla riga ' + Transform(CGMovRIva.Riga) + '.' + Chr(13) + Chr(13) + ;

		** 																							'Si ricorda che le oparazioni MOSS vengono applicate a servizi.' + Chr(13) + Chr(13) + ;

		** 																							'Proseguo ?'), MB_ICONEXCLAMATION + MB_YESNO + MB_DEFBUTTON2, oApp.AppName + ' * IVA MOSS *') = IDNO

		** 	Return .F.

		** 

		** EndIf



	EndScan

		

	Select DoRigSpesa

	Scan

		

		If DorigSpesa.IvaMoss And !lIvaMoss And ;

			xMessageBox(Thisform.TB_(,'729055D9-D9BD-4EF7-8BB5-45D5616771B3', 'Rilevato codice iva MOSS non permesso alla riga spesa ' + Transform(DorigSpesa.Riga) + '.' + Chr(13) + Chr(13) + ;

																									'Verificare che il cliente <' + Alltrim(oCF.Cd_CF) + '> sia un consumatore finale appartenente ad uno stato membro UE.' + Chr(13) + Chr(13) + ;

																									'Proseguo ?'), MB_ICONEXCLAMATION + MB_YESNO + MB_DEFBUTTON2, oApp.AppName + ' * IVA MOSS *') = IDNO

			Return .F.



		EndIf

		

	EndScan



EndIf





ENDPROC

PROCEDURE checkivasplit

Local nCount, oWA, cText, lRet



oWA 	= SelectWA('Dorig')

cText	= ''

lRet	= .T.



If Dotes.IvaSplit



	Select DoRig

	Scan

		

		cText = cText + Iif(DoRig.Omaggio = 3, 'Rilevato omaggio iva non compatibile nella riga ' + Transform(Dorig.Riga) + Chr(13), '')



	EndScan



	If !Empty(cText) And xMessageBox(Thisform.TB_(,'ED1CE841-19A4-4CFF-9FB7-686112731AF5', cText + Chr(13) + Chr(13) + 'Proseguo ?'), MB_ICONEXCLAMATION + MB_YESNO + MB_DEFBUTTON2, oApp.AppName + ' * SCISSIONE PAGAMENTI *') = IDNO

		lRet = .F.

	EndIf



EndIf



** Verifica che non sia usato codice iva split (è filtrato nei campi dei codici iva)



Return lRet

ENDPROC

PROCEDURE ivamoss_set

Local oCF



oCF = Iif(!ThisForm.PF.pgGenerale.PF.pgGenerale.txtCF_Fatt.Field.Isempty(), ThisForm.PF.pgGenerale.PF.pgGenerale.txtCF_Fatt.Field.FKRecord, ThisForm.PF.pgGenerale.txtCd_CF.Field.FKRecord)

Return ;

	oApp.LicInfo.IvaMoss And ;

	DoTes.Clifor == 'C' And oCF.ConsumatoreFinale And ;

 	xSQLExec2Bit('Exists(Select * From Nazione Where Cd_nazione = ' + FormatC4SPT(oCF.Cd_Nazione) + ' And Ue = 1)')



ENDPROC

PROCEDURE ca_datarif

Return Iif(DOTes.Clifor == 'F', Evl(Nvl(DOTes.DataDocRif, DOTes.DataDoc), DOTes.DataDoc), DOTes.DataDoc)

ENDPROC

PROCEDURE cmdddtxml

Do Create_Peppol_DDT In 'Forms\Peppol.fxp' With Thisform, DoTes.Id_DOTes

ENDPROC

PROCEDURE showhidepeppol

Lparameters lOnlyMove



With This.PF.PgGenerale.PF.pgGenerale



	If !lOnlyMove

		.cntPeppol.Visible = This.Mode = FEDIMODE_SHOW And ;

									(oApp.LicInfo.Peppol > 0 Or oApp.LicInfo.PeppolPas) And ;

									!IsEmpty(DoTes.PeppolOrder) Or !IsEmpty(DoTes.PeppolDespatch)

	EndIf 



	Do Case

		Case .cntPeppol.Visible And .cntConservazioneInvio.Visible

			ObjMov(.cntPeppol,				, .cntStato.Top)

			ObjMov(.cntConservazioneInvio,, .cntPeppol.Bottom + 4)



		Case .cntPeppol.Visible And !.cntConservazioneInvio.Visible

			ObjMov(.cntPeppol,				, .cntStato.Top)



		Case !.cntPeppol.Visible And .cntConservazioneInvio.Visible

			ObjMov(.cntConservazioneInvio,, .cntStato.Top)

		

	EndCase 



*!*		If PemStatus(This.PF.pgGenerale.PF.pgGenerale, 'cntFactoring', 5)

*!*			If Bitand(Thisform.DOBitMask,0x0000000008) > 0 Or Bitand(Thisform.DOBitMask,0x0000000010) > 0

*!*				ObjMov(.cntFactoring, , .cntConservazioneInvio.Bottom + 4)

*!*				.cntFactoring.Visible = .T.

*!*			Else

*!*				.cntFactoring.Visible = .F.

*!*			EndIf 

*!*		EndIf 

** Peppol funziona solo per gli ordini e DDT del ciclo attivo

** Factoring funziona solo per le fatture e fatture accompagnatorie del ciclo attivo

** Quindi questo codice potremmo anche toglierlo perchè non avremmo mai il blocco Peppol con il blocco Factoring

** Lascio però il codice nel caso in cui gestiremo Peppol con le fatture

	If PemStatus(This.PF.pgGenerale.PF.pgGenerale, 'cntFactoring', 5)		

		This.PF.pgGenerale.PF.pgGenerale.cntFactoring.Refresh()

		If .cntFactoring.Visible = .T.

			ObjMov(.cntFactoring, , .cntConservazioneInvio.Bottom + 4)		

		EndIf 

	EndIf 



EndWith 

ENDPROC

PROCEDURE setregimeiva

** cScope -> nome simbolico per il do case



**	Si imposta iva differita se:



**	1) Il soggetto è un ente pubblico e deve essere gestita l'iva sospesa. Dovrebbe essere la condizione generale della norma ma lasciamo flex in caso

**		sia necessaria qualche gestione particolare. Magari un ente pubblico non assogettato all'art. 6

**	2) Il soggetto (CF) e l'attività  (CGLIQ) rientrano nella gestione dell'iva per cassa.

**	3) La registrazione è una vendita o un acquisto NON in regime di reverse charge (tipofattura = 0)

** 4) NON è un ente pubblico in regime di scissione dei pagamenti.

** 5) E' un'operazione imponibile. Dal punto di vista del conteggio dell'imposta non cambia nulla ma non essendoci il requisito di esigibilità  dell'iva non è applicabile formalmente il regime.

**		Ne consegue che non deve essere conteggiato in liquidazione periodica nemmeno il rispettivo imponibile.



** xoldValue -> Passato soltanto nei casi in cui viene richiemato da qualche onvaluechange



Lparameters cScope, xoldValue



Local lIva, lSplit, nCurWA

Local oCF, oDo, oRC, oTxtCd_CF



With ThisForm.PF.PGGenerale



nCurWA		= Select(0)

cScope	 	= Upper(Evl(cScope, 'USERINTERFACE'))

oTxtCd_CF 	= Iif(!IsEmpty(DoTes.Cd_CF_Fatt), .PF.pgGenerale.txtCF_Fatt, .txtCd_CF)



** Devo essere sicuro che il valore dei field sia sincronizzato con il controlsource

** Il metodo e bindato con il PF.REFRESH()



oCF			= Iif(Type("oTxtCd_CF.Field.FKRecord") == 'O', oTxtCd_CF.Field.FKRecord, ;

						xSQLExec2Obj('Select Cd_CF, EntePubblico, IvaSospesa, IvaSplit, Cliente, Fornitore, Cd_ReverseCharge From CF Where Cd_CF = ' + FormatC4SPT(Nevl(DoTes.Cd_CF_Fatt, DoTes.Cd_CF)), .T.))



oDO			= Iif(Type(".txtCd_DO.Field.FKRecord") == 'O', .txtCd_DO.Field.FKRecord, ;

						xSQLExec2Obj('Select Cd_DO, TipoDocumento, Clifor, Cd_CGCausale From DO Where Cd_Do = ' + FormatC4SPT(DoTes.Cd_Do), .T.))



oRC			= Iif(Type(".PF.pgGenerale.cntDatiContabili.txtCd_ReverseCharge.Field.FKRecord") == 'O', .PF.pgGenerale.cntDatiContabili.txtCd_ReverseCharge.Field.FKRecord, ;

						xSQLExec2Obj('Select * From ReverseCharge Where Cd_ReverseCharge = ' + FormatC4SPT(DoTes.Cd_ReverseCharge), .T.))



Do Case



	Case InList(cScope, 'USERINTERFACE')

	

		.PF.PgGenerale.cntDatiContabili.ChkIvaSplit.Visible	= (BitAnd(TD_CA_DOCIVA, DoTypeAsMask(oDo.TipoDocumento, oDo.CliFor)) != 0) Or (DoTes.IvaSplit)

		.PF.PgGenerale.cntDatiContabili.ChkIvaSospesa.Visible	= (BitAnd(TD_DOCIVA, 	DoTypeAsMask(oDO.TipoDocumento, oDo.CliFor)) != 0) Or (DoTes.IvaSospesa)

		.PF.PgGenerale.cntDatiContabili.ChkIvaSospesa.Enabled	= !DoTes.IvaSplit Or DoTes.IvaSospesa



		** .PF.pgGenerale.cntDatiContabili.txtCd_ReverseCharge.SetAll('Enabled', Inlist(oDo.TipoDocumento, 'F', 'A', 'N'))

		.PF.pgGenerale.cntDatiContabili.txtCd_ReverseCharge.Label.caption = Iif(oDo.Clifor == 'F', TX_(, "0D06863C-B9A4-4543-B170-BF9574091542", 'Reverse Charge'), TX_(, "060B5542-16AA-4C09-8A1C-0E72534D84E1", 'Tipo Fattura'))



	Case InList(cScope, 'COLSINTERFACE')



		** Sono pagine dinamiche per cui non ho garanzia che le grid esistano



		** Se c'è un codice in testa non si vedono le righe perché prevale su tutto

		** Il codice si può cambiare soltanto per il ciclo passivo in presenza di aliquote libere (senza codice in anagrafica)



		If PemStatus(.PF.pgRighe, 'Cnt', 5)

			.PF.pgRighe.Cnt.Grid.ColCd_ReverseCharge.Visible = (IsEmpty(DoTes.Cd_ReverseCharge))

			.PF.pgRighe.Cnt.Grid.ColCd_ReverseCharge.Enabled = (IsEmpty(Dotes.Cd_ReverseCharge) And Dotes.Clifor == 'F')

		EndIf

		

		If PemStatus(.PF.pgPiede, 'Cnt', 5)

			.PF.pgPiede.Cnt.cntFattura.Grid.ColCd_ReverseCharge.Visible = (IsEmpty(DoTes.Cd_ReverseCharge))

			.PF.pgPiede.Cnt.cntFattura.Grid.ColCd_ReverseCharge.Enabled	= (IsEmpty(Dotes.Cd_ReverseCharge) And Dotes.Clifor == 'F')

		EndIf



	** ------------------------------------------------------------

	

	Case InList(cScope, 'ONEROW+R', 'ONEROW+R-RC')

	

		** Non altero il codice se richiamato da OVC del RC

		If !InList(cScope, 'ONEROW+R-RC')

		

			** Rilevo il tipo di RC da assegnare all'operazione iva (SOLO FATTURE A/V e giroconti compensativi)

			** In caso di RC SPL faccio prevalere quello dichiarato nell'aliquota in quanto secondo norma ha priorità 

			Replace Cd_ReverseCharge With Iif(Dotes.Tipofattura = RC_SPL, Nevl(Dorig.Cd_Rc, Dotes.Cd_ReverseCharge), Nevl(Dotes.Cd_ReverseCharge, Dorig.Cd_Rc)) In Dorig



			** Annullo il codice:

			** -- In caso di cessione non riporto il codice SPL

			** -- In caso di SP separato elimino per sicurezza il rif ad RC

			Replace Cd_ReverseCharge With ICase((Dotes.Clifor == 'C' And Indexseek(Dorig.Cd_ReverseCharge, .T., 'ReverseCharge', 'Cd_RC') And ReverseCharge.TipoFattura = RC_SPL), Null, Dorig.Cd_ReverseCharge) In Dorig

		

		EndIf



		** Aggiorno il tipofattura (Se non trova nulla va in eof)

		Seek Dorig.Cd_ReverseCharge Order Tag Cd_RC In ReverseCharge

		Replace TipoFattura With Nvl(ReverseCharge.TipoFattura, 0) In Dorig



	Case InList(cScope, 'ONEROW+S', 'ONEROW+S-RC')

	

		** Non altero il codice se richiamato da OVC del RC

		If !InList(cScope, 'ONEROW+S-RC')

		

			** Rilevo il tipo di RC da assegnare all'operazione iva (SOLO FATTURE A/V e giroconti compensativi)

			** In caso di RC SPL faccio prevalere quello dichiarato nell'aliquota in quanto secondo norma ha priorità 

			Replace Cd_ReverseCharge With Iif(Dotes.Tipofattura = RC_SPL, Nevl(Dorigspesa.Cd_Rc, Dotes.Cd_ReverseCharge), Nevl(Dotes.Cd_ReverseCharge, Dorigspesa.Cd_Rc)) In Dorigspesa



			** Annullo il codice:

			** -- In caso di cessione non riporto il codice SPL

			** -- In caso di SP separato elimino per sicurezza il rif ad RC

			Replace Cd_ReverseCharge With ICase((Dotes.Clifor == 'C' And Indexseek(Dorigspesa.Cd_ReverseCharge, .T., 'ReverseCharge', 'Cd_RC') And ReverseCharge.TipoFattura = RC_SPL), Null, Dorigspesa.Cd_ReverseCharge) In Dorigspesa

		

		EndIf



		** Aggiorno il tipofattura (Se non trova nulla va in eof)

		Seek DorigSpesa.Cd_ReverseCharge Order Tag Cd_RC In ReverseCharge

		Replace TipoFattura With Nvl(ReverseCharge.TipoFattura, 0) In DorigSpesa



	Case InList(cScope, 'ALLROWS')

		

		If Reccount('DoRig') != 0 

			oWA = SelectWA('DoRig')

			Scan

				This.SetRegimeIva('ONEROW+R')

			EndScan

		EndIf			



		If Reccount('DoRigSpesa') != 0 

			oWA = SelectWA('DoRigSpesa')

			Scan

				This.SetRegimeIva('ONEROW+S')

			EndScan

		EndIf			



	** ------------------------------------------------------------



	Case InList(cScope, 'CF')

	

		.PF.pgGenerale.cntDatiContabili.txtCd_ReverseCharge.Field.lSkipMessage = .T.

		.PF.pgGenerale.cntDatiContabili.txtCd_ReverseCharge.Field.SetValue(oCF.Cd_ReverseCharge, .T.)

		.PF.pgGenerale.cntDatiContabili.txtCd_ReverseCharge.Field.lSkipMessage = .F.



		cCd_CGLiq = Nevl(xSqlExec2Var('Select C.Cd_CGLiq From CGCausale C Left Join CGLiq L on L.Cd_CGliq = C.Cd_CGLiq Where C.Cd_CGCausale = ' + FormatC4SPT(oDo.Cd_CGCausale)), Thisform.De.CGLiq.Prevalente.Cd_CGLiq)

		Seek cCd_CGLiq Order Tag Cd_CGLiq In CGLiq



		** IvaSospesa

		lIva = oCF.IvaSospesa

		Iif(.PF.PgGenerale.cntDatiContabili.ChkIvaSospesa.Visible, .PF.PgGenerale.cntDatiContabili.ChkIvaSospesa.SetValue(lIva), .T.)



		** Iva Split -> Per effetto del IIF non viene impostato ivasplit su documenti in cui NON è visibile il check (NO ORDINI/DDT o DOC a privati)

		lSplit = (oCF.IvaSplit And oCF.Cliente)

		Iif(.PF.PgGenerale.cntDatiContabili.ChkIvaSplit.Visible, .PF.PgGenerale.cntDatiContabili.ChkIvaSplit.SetValue(lSplit), .T.)



	Case InList(cScope, 'IVASPLIT')

	

		Local lIvaSospesa

		

		** Non rileva iva x cassa perché potrei applicare la sospesione per altri motivi

		lIvaSospesa = (oCf.IvaSospesa And (IsEmpty(DoTes.Cd_ReverseCharge) Or DoTes.TipoFattura = RC_SPL))



		.PF.pgGenerale.cntDatiContabili.chkIvaSospesa.Enabled = Iif(BitAnd(TD_CA_DOCIVA, DoTypeAsMask(oDo.TipoDocumento, oDo.CliFor)) != 0, !DoTes.IvaSplit, .PF.pgGenerale.cntDatiContabili.chkIvaSospesa.Enabled)

		.PF.pgGenerale.cntDatiContabili.chkIvaSospesa.SetValue(lIvaSospesa And !DoTes.IvaSplit, .T.)

		

	Case InList(cScope, 'IVASOSPESA')

	

		Iif(DoTes.IvaSospesa, .PF.pgGenerale.cntDatiContabili.chkIvaSplit.SetValue(.F.), .T.)

		

	Case InList(cScope, 'TIPOFATTURA')

	

		.PF.pgPiede.Cnt.cntFattura.Grid.ColCd_ReverseCharge.Enabled	= (IsEmpty(Dotes.Cd_ReverseCharge) And Dotes.Clifor == 'F')

		.PF.pgRighe.Cnt.Grid.ColCd_ReverseCharge.Enabled				= (IsEmpty(Dotes.Cd_ReverseCharge) And Dotes.Clifor == 'F')

		

		** Gestisco con interazione dell'utente il caso di cancellazione della causale RC dalla testa

		** If (Inlist(oDo.TipoDocumento, 'F', 'A', 'N') And Dotes.Clifor == 'F') And

		**	If Dotes.Clifor == 'F' And ;

		**		!IsEmpty(xOldValue) And IsEmpty(Dotes.Cd_ReverseCharge) And (Reccount('Dorig') != 0 Or Reccount('DorigSpesa') != 0) And ;

		**		xSQLExec2Var('Select Tipofattura From ReverseCharge Where Cd_ReverseCharge = ' + FormatC4SPT(xOldValue)) != 1 And ;

		**		xMessageBox(Thisform.TB_(,'F8EF27C6-5470-45DD-A42C-CA20E0312175', ;

		**			'Mantenere la causale Reverse Charge nelle righe del documento?' + Chr(13) + Chr(13) + ;

		**			'La causale sarà  preservata soltanto per i codici iva non dedicati.'), MB_YESNO + MB_ICONQUESTION + MB_DEFBUTTON2) = IDYES



		**		Replace Cd_ReverseCharge With Dorig.Cd_RC 		For !IsEmpty(Dorig.Cd_RC) 			In Dorig

		**		Replace Cd_ReverseCharge With Dorigspesa.Cd_RC 	For !IsEmpty(Dorigspesa.Cd_RC) 	In DorigSpesa



		**	Else

		**			

		**		Replace Cd_ReverseCharge With Nevl(DoTes.Cd_ReverseCharge, Dorig.Cd_RC) 		For !Dorig.Iva_Split_Sep 		In Dorig

		**		Replace Cd_ReverseCharge With Nevl(DoTes.Cd_ReverseCharge, Dorigspesa.Cd_RC) For !DorigSpesa.Iva_Split_Sep In DorigSpesa



		**	EndIf



		This.SetRegimeIva('COLSINTERFACE')

		This.SetRegimeIva('ALLROWS')

		

	Otherwise

	

		xMessagebox(Textmerge('Method SETREGIMEIVA : <<<cScope>>> not supported.'))

		

EndCase



EndWith



Select(nCurWA)



ENDPROC

PROCEDURE fte_isxmlpa

Return This.Fte_Isxml() And xSQLExec2Bit(Textmerge("Exists(Select * From CF Where Cd_CF = <<FormatC4Spt(xDefault(DoTes.Cd_CF_Fatt, DoTes.Cd_CF))>> And EntePubblico = 1 And CodiceIPA Is Not Null)"))



ENDPROC

PROCEDURE fte_isxmlpr

Return This.Fte_Isxml() And xSQLExec2Bit(Textmerge("Exists(Select * From CF Where Cd_CF = <<FormatC4Spt(xDefault(DoTes.Cd_CF_Fatt, DoTes.Cd_CF))>> And EntePubblico = 0 And CodiceFPR Is Not Null)"))



ENDPROC

PROCEDURE rc_check

Local cText, lRet, oWA



oWA 	= SelectWA('DoRig')

cText = ''

lRet 	= .T.



If !IsEmpty(DoTes.Cd_ReverseCharge) And !Inlist(DoTes.TipoFattura, RC_SPL, RC_UE)



	** Controllo se esistono codici rc da aliquote diversi da quello in testa (RIGHE)

	Select DoRig

	Scan For !IsEmpty(Cd_RC) And !(Dotes.Cd_ReverseCharge == Cd_RC)

		cText = cText + Textmerge('- Riga <<DoRig.Riga>> : Causale RC <<Alltrim(DoRig.Cd_RC)>> non coerente con RC principale <<Alltrim(Dotes.Cd_ReverseCharge)>>') + Chr(13)

	EndScan



	** Controllo se esistono codici rc da aliquote diversi da quello in testa (SPESE)

	Select DoRigSpesa

	Scan For !IsEmpty(Cd_RC) And !(Dotes.Cd_ReverseCharge == Cd_RC)

		cText = cText + Textmerge('- Riga spesa <<DoRigSpesa.Riga>> : Causale RC <<Alltrim(DoRigSpesa.Cd_RC)>> non coerente con RC principale <<Alltrim(Dotes.Cd_ReverseCharge)>>') + Chr(13)

	EndScan



	If !Empty(cText) And ;

		xMessageBox(Thisform.TB_(,'91368617-0778-49BA-ABBC-AD579304FC15', "Rilevata incongruenza tra causale RC in riga e causale RC principale" + Chr(13) + Chr(13) + cText + Chr(13) + ;

																								"Procedi?"), MB_IQYNDB2) = IDNO

		lRet = .F.

		

	EndIf

	

	Go Top In DoRig

	Go Top In DoRigSpesa

	

EndIf



Return lRet



ENDPROC

PROCEDURE cmddointento

Lparameters cAlias



Local cTipo, nId



cAlias 	= Upper(cAlias)

cTipo		= Iif(cAlias == 'DORIG', 'R', 'S')

nId		= Iif(cAlias == 'DORIG', Dorig.Id_Dorig_Evade, Dorigspesa.Id_Dorigspesa_Evade)



** Escludo dalla gestione righe descrittive

If IsEmpty(&cAlias..Cd_Aliquota) And IsEmpty(&cAlias..PrezzoTotaleV)

	Return .T.

EndIf



** Escludo riga riFerimento per documenti prelevati (solo righe)

If (cAlias == 'DORIG') And !IsEmpty(&cAlias..TipoRigaRif)

	Return .T.

EndIf



** Escludo se non è presente alcuna dichiarazione in show

If Thisform.Mode = FEDIMODE_SHOW And IsEmpty(&cAlias..DoIntento) And IsNull(Thisform.DoIntento_Evade(cTipo, nId))

	Return .T.

EndIf



Thisform.DOIntento_Show(cAlias)





ENDPROC

PROCEDURE dointento_show

Lparameters cAlias



Local oForm, oParm, oWa

Local oRec, cTipo, nId



** In modalità show devo garantire la presenza dei cursori DORIG/DORIGSPESA

Iif(Thisform.Mode = FEDIMODE_SHOW And ThisForm.PF.pgGenerale.PF.pgRighe.ControlCount = 0, ThisForm.PF.pgGenerale.PF.DynamicPageInit(ThisForm.PF.pgGenerale.PF.pgRighe) And ThisForm.PF.pgGenerale.PF.pgRighe.Refresh(), .T.)

Iif(Thisform.Mode = FEDIMODE_SHOW And ThisForm.PF.pgGenerale.PF.pgPiede.ControlCount = 0, ThisForm.PF.pgGenerale.PF.DynamicPageInit(ThisForm.PF.pgGenerale.PF.pgPiede) And ThisForm.PF.pgGenerale.PF.pgPiede.Refresh(), .T.)



cAlias 	= Upper(cAlias)

cTipo		= Iif(cAlias = 'DORIG', 'R', 'S')

nId		= Iif(cAlias = 'DORIG', Dorig.Id_Dorig_Evade, Dorigspesa.Id_Dorigspesa_Evade)

oWa 		= SelectWA(cAlias)



Scatter Name oParm Memo

oRec = Thisform.DOIntento_Evade(cTipo, nId)



AddProperty(oParm, 'Alias', cAlias)

AddProperty(oParm, 'RetCode', 0)

AddProperty(oParm, 'DoIntentoEvade', Iif(!IsNull(oRec), oRec.ExtraInfo, Null))

AddProperty(oParm, 'TipoDocumento',  Dotes.TipoDocumento)

AddProperty(oParm, 'DataRif',  		 NEvl(Iif(Dotes.Clifor == 'F', Dotes.DataDocRif, Null), Dotes.DataDoc))



** Default DataSession

oForm = RunGeneric('Fedi_DocCommon', This, 'dointento_pick', oParm)



If Vartype(oForm) == 'O'



	oForm.Show(1)



	** In caso di riga che ha evaso un DDT non applico alcuna modifica

	If This.Mode != FEDIMODE_SHOW And !oForm.DoEvade



		If oForm.WasConfirmed

			

			Replace ;

				Cd_Aliquota_e 	With oForm.Cd_Aliquota_e ;

				Cd_Aliquota_r	With Nvl(&cAlias..Cd_Aliquota_e, &cAlias..Cd_Aliquota) ;

				Dointento 		With oForm.XmlOut ;

				In (cAlias)

			

		Else

		

			** Se per caso inserisco a mano il codice e poi esco con annulla lo elimino se non è presente alcuna dichiarazione collegata

			oParm.RetCode = -2

			

		EndIf

	

	EndIf

	

	oForm.Release()



Else



	** RetoCode arriva direttamente dalla form in modo che sia possibile eventualmente differenziare i messaggi di errore



EndIf



** In caso di Ret code negativo elimino il codice inserito perché vuol dire che non posso applicare esenzioni

If oParm.RetCode < 0 And !IsEmpty(&cAlias..Cd_Aliquota_e) And IsEmpty(&cAlias..Dointento)



	Replace Cd_Aliquota_e With Null In (cAlias)

	

EndIf



ICase(oParm.RetCode = -1, xMessageBox(Thisform.TB_(,'1BBF97CB-DEE5-4EF6-8BDD-8226AB67A69D', 'Non è stata rilevata alcuna dichiarazione applicabile.'), MB_ICONSTOP), .T.)



ENDPROC

PROCEDURE dointento_clear

**	nSection	: 	0x01 -> Righe

**					0x02 -> Spese



Lparameters nSection



nSection = Evl(nSection, 0x01 + 0x02)



If Bitand(nSection, 0x01) != 0

	

	Replace Cd_Aliquota_e With Null, DoIntento With Null For !IsEmpty(DoIntento) Or !IsEmpty(Cd_Aliquota_e) In Dorig

	Go Top In Dorig



EndIf



If Bitand(nSection, 0x02) != 0

	

	Replace Cd_Aliquota_e With Null, DoIntento With Null For !IsEmpty(DoIntento) Or !IsEmpty(Cd_Aliquota_e) In DorigSpesa

	Go Top In DorigSpesa

	

EndIf





ENDPROC

PROCEDURE dointento_check

Local oDo, Owa

Local oForm, oParm

Local lRet



oWa 	= SelectWA()

oDo 	= ThisForm.PF.pgGenerale.txtCd_DO.Field.FKRecord

lRet	= .T.



If !Thisform.DoIntento Or !oDo.DICheck

	Return .T.

EndIf



Select DoRig

Locate For !IsEmpty(DoIntento)



Select DoRigSpesa

Locate For !IsEmpty(DoIntento)



If !Found('DoRig') And !Found('DoRigSpesa')

	Return .T.

EndIf



oForm = RunGeneric('Fedi_DocCommon', Thisform, 'dointento_check')

If Vartype(oForm) = 'O'

	oForm.Show(1)

	lRet = oForm.WasConfirmed

	oForm.Release()

EndIf



Return lRet 

ENDPROC

PROCEDURE dointento_visible

Lparameters lApply



** This.DoIntento = Nvl(Iif(!IsEmpty(Dotes.Cd_Do), xSQLExec2Var('Select DIEnabled From Do Where Cd_DO = ' + FormatC4SPT(Dotes.Cd_Do)), .F.), .F.)

** This.DoIntento = (DoTes.DIEnabled And (Dotes.Esecutivo Or DoTes.DIExecutive)) && Per non visualizzare la colonna in caso di doc non esecutivo



oDo = Iif(!IsEmpty(Dotes.Cd_Do), xSQLExec2Obj('Select DIEnabled, DISave, Fte_NotaIva From Do Where Cd_DO = ' + FormatC4SPT(Dotes.Cd_Do), .T.), Null)



This.DoIntento = Iif(!IsNull(oDo), oDo.DIEnabled And !oDo.Fte_NotaIva, .F.)

This.DoIntento = (This.DoIntento And xSQLExec2Bit('Exists(Select * From CFEsenzione Where Cd_CF = ' + FormatC4SPT(Dotes.Cd_CF) + ')'))



If lApply

	Thisform.PF.PGGenerale.PF.PGRighe.Cnt.Grid.ColDoIntento.Visible 				= This.DoIntento

	Thisform.PF.PGGenerale.PF.PGPiede.Cnt.CntFattura.Grid.ColDoIntento.Visible = This.DoIntento

	Thisform.PF.PGGenerale.PF.PGRighe.Cnt.Grid.ColDoIntento.Enabled 				= Iif(!IsNull(oDo), (!oDo.DISave Or Bitand(Thisform.Mode, FEDIMODE_INS_DUP) = 0), .T.)

	Thisform.PF.PGGenerale.PF.PGPiede.Cnt.CntFattura.Grid.ColDoIntento.Enabled = Iif(!IsNull(oDo), (!oDo.DISave Or Bitand(Thisform.Mode, FEDIMODE_INS_DUP) = 0), .T.)

EndIf

	

Return This.DoIntento



ENDPROC

PROCEDURE dointento_apply

**	nSection	: 	0x01 -> Righe

**					0x02 -> Spese



Lparameters nSection



Local oWA, oData, oRec



If !Thisform.DoIntento Or IsEmpty(Substr(NEvl(Dotes.Cd_CF_Fatt, Dotes.Cd_CF), 2)) Or IsEmpty(Dotes.Cambio)

	Return .T.

EndIf



oWA = SelectWA()



nSection = Evl(nSection, 0x01 + 0x02)



** ------- RIGHE



If Bitand(nSection, 0x01) != 0



	Select Dorig

	Scan 



		If IsEmpty(Dorig.Cd_Aliquota) Or IsEmpty(Dorig.PrezzoTotaleV) Or Nvl(Dorig.TipoPC, '') == 'C'

			Loop

		EndIf



		If !IsEmpty(DoRig.Id_DOrig_Evade) 

		

			oRec = Thisform.DoIntento_Evade('R', DoRig.Id_DOrig_Evade)

			

			If Vartype(oRec) == 'O'

				

				Replace Cd_Aliquota_e With Iif(oRec.ExtraInfoPresent, oRec.Cd_Aliquota_e, Null) In Dorig

				

				** Se la Di è stata applicata al documento che ne prevede gestione mantengo il codice mentre gli estremi rimangono sempre nel documento evaso

				** Necessario per non portare avanti codice di esenzione inserito per errore dalla vecchia gestione in documenti tipo ordine o comunque

				** non abilitati alla gestione

				If oRec.DIEnabled

					Loop

				EndIf

					

			EndIf

			

		EndIf

		

		If (Dotes.Esecutivo Or Dotes.DIExecutive)



			oData = Thisform.oDointento.Get_Aliquota( ;

			  NEvl(Dotes.Cd_CF_Fatt, Dotes.Cd_CF) ;

			, Dotes.Cd_DO ;

			, Dorig.Cd_Ar ;

			, Dorig.Cd_Aliquota ;

			, Dorig.Cd_ReverseCharge ;

			, NEvl(Iif(Dotes.Clifor == 'F', Dotes.DataDocRif, Null), Dotes.DataDoc) ;

			, Round(Dorig.PrezzoTotaleV/DoTes.Cambio, 2) ;

			, Dotes.ImportiIvati ;

			, Dotes.Esecutivo ;

			, Dorig.Id_DORig_Evade ;

			, Null ;

			, Thisform.oDointento.Get_Buffer_Esclude() ;

			, Thisform.oDointento.Get_Buffer_Edit())



			If Vartype(oData) = 'O'



				Replace ;

					Cd_Aliquota_e 	With oData.Cd_Aliquota_e ;

					Cd_Aliquota_r 	With oData.Cd_Aliquota_r ;

					DoIntento		With oData.ExtraInfo ;

					DoIntentoCode	With oData.ErrorCode ;

					In Dorig

				

			EndIf

		

		EndIf

		

	EndScan



	Replace Cd_Aliquota_r With xDefault(Cd_Aliquota_e, Cd_Aliquota) All In DoRig

	Go Top In Dorig



EndIf



** ------- SPESE



If Bitand(nSection, 0x02) != 0



	Select DorigSpesa

	Scan



		If IsEmpty(Dorigspesa.Cd_Aliquota) Or (IsEmpty(Dorigspesa.ImportoV) And IsEmpty(Dorigspesa.Perc))

			Loop

		EndIf



		If !IsEmpty(Dorigspesa.Id_DOrigSpesa_Evade) 

		

			oRec = Thisform.DoIntento_Evade('S', DoRig.Id_DOrig_Evade)

			

			If Vartype(oRec) == 'O'

				

				Replace Cd_Aliquota_e With Iif(oRec.ExtraInfoPResent, oRec.Cd_Aliquota_e, Null) In Dorigspesa

					

				** Se la Di è stata applicata al documento che ne prevede gestione mantengo il codice mentre gli estremi rimangono sempre nel documento evaso

				If oRec.DIEnabled

					Loop

				EndIf

					

			EndIf

			

		EndIf

		

		If (Dotes.Esecutivo Or Dotes.DIExecutive)

		

			oData = Thisform.oDointento.Get_Aliquota( ;

			  NEvl(Dotes.Cd_CF_Fatt, Dotes.Cd_CF) ;

			, Dotes.Cd_DO ;

			, Null ;

			, DorigSpesa.Cd_Aliquota ;

			, DorigSpesa.Cd_ReverseCharge ;

			, NEvl(Iif(Dotes.Clifor == 'F', Dotes.DataDocRif, Null), Dotes.DataDoc) ;

			, Iif((IsEmpty(DoRigSpesa.ImportoV) And !IsEmpty(DoRigSpesa.Perc)), Evl(Iif(This.PF.pgGenerale.PF.pgPiede.ControlCount > 0, Round(This.PF.pgGenerale.PF.pgPiede.Cnt.CalcolaSpesePerc() / Dotes.Cambio, 2), 1), 1), Round(DorigSpesa.ImportoV/DoTes.Cambio, 2)) ;

			, Dotes.ImportiIvati ;

			, Dotes.Esecutivo ;

			, Null ;

			, DorigSpesa.Id_DORigSpesa_Evade ;

			, Thisform.oDointento.Get_Buffer_Esclude() ;

			, Thisform.oDointento.Get_Buffer_Edit())



			If Vartype(oData) = 'O'



				Replace ;

					Cd_Aliquota_e 	With oData.Cd_Aliquota_e ;

					Cd_Aliquota_r 	With oData.Cd_Aliquota_r ;

					DoIntento		With oData.ExtraInfo ;

					DoIntentoCode	With oData.ErrorCode ;

					In DorigSpesa

				

			EndIf

		

		EndIf

		

	EndScan



	Replace Cd_Aliquota_r With xDefault(Cd_Aliquota_e, Cd_Aliquota) All In DoRigSpesa

	Go Top In DorigSpesa



EndIf



ENDPROC

PROCEDURE dointento_evade

** cTipo			= 'R' -> Righe ; 'S' -> Spese

** nId 			= Id_DoRig_Evade; Id_DoRigSpesa_Evade



Lparameters cTipo, nId



Local oRec



If !InList(xDefault(cTipo, ''), 'R', 'S')

	Return Null

EndIf



nId = xDefault(nId, Iif(cTipo == 'R', Dorig.Id_DoRig_Evade, Dorigspesa.Id_Dorigspesa_Evade))



If IsEmpty(nId)

	Return Null

EndIf



oRec = ICase(;

	cTipo == 'R', xSQLExec2Obj(Textmerge("Select Top 1 * From Do_Intento_Evade_R(<<nId>>, 0x02) Where ExtraInfoPresent = 1 Or (DIEnabled = 1 And TipoBeneServizio = 'B' And TipoDocumento In ('B')) Order By Id")), ;

	cTipo == 'S', xSQLExec2Obj(Textmerge("Select Top 1 * From Do_Intento_Evade_S(<<nId>>, 0x02) Where ExtraInfoPresent = 1 Or (DIEnabled = 1 And TipoBeneServizio = 'B' And TipoDocumento In ('B')) Order By Id")), ;

	Null)



Return oRec

ENDPROC

PROCEDURE cmdfteview

This.PF.pgGenerale.PF.pgGenerale.cntConservazioneInvio.imgOperazioni.Click()

ENDPROC

PROCEDURE fte_save

** Valorizzo eventuali campi dei dati aggiuntivi per fattura elettronica nel caso non lo fossero gia.



Local oTot, oDoRec, cAlias



** solo in INS, Ciclo attivo, FE

If This.Mode != FEDIMODE_INS Or Empty(Bitand(DoTes.DOBitMask, TD_CA_TUTTO_USED)) Or !This.Fte_IsXml()

	Return .T.

EndIf



oDoRec 	= This.PF.pgGenerale.txtCd_Do.Field.FKRecord	

oTot 		= This.TotaleDocumento()



** Applico il bollo virtuale

If Vartype(oTot) == 'O' And InList(oDoRec.TipoDocumento, 'F', 'A', 'N') And ;

	(Impostazione.Imp_DOEsente_Limite > 0) And (Impostazione.Imp_DOEsente_Spese > 0) And ;

	(oTot.TotEsenteBolloE >= Impostazione.Imp_DOEsente_Limite)



	cAlias = This.oFteXml.Alias_TDOC

	This.oFteXml.TDoc_XMLToCursor(Dotes.Fte_Xml)



	If IsEmpty(&cAlias..DG_BolloVirtuale) Or IsEmpty(&cAlias..DG_ImportoBollo)



		Replace ;

			DG_BolloVirtuale	With xDefault(&cAlias..DG_BolloVirtuale, .T.) ;

			DG_ImportoBollo	With xDefault(&cAlias..DG_ImportoBollo, Impostazione.Imp_DOEsente_Spese) ;

		In (cAlias)

		

		Replace FTE_Xml With This.oFtexml.TDoc_CursorToXML() In Dotes



	EndIf

	

	This.oFtexml.TDoc_WA_Destroy()

		

EndIf



ENDPROC

PROCEDURE fte_check

** Dovrebbe richiamare un metodo dell'oggetto ftexml che ritorna l'elenco dei possibili errori in base alle specifiche tecniche.

** Non sarebbe un grosso problema farlo per id sul server ma bisogna pensarlo con i dati del client prima della conferma.

** Si devono passare in formato XML/JSON i dati di testa e righe e fare i controlli



** cScope -> nome simbolico per il do case



Lparameters cScope



Local cAlias, cCd_CF, cIdFiscaleDitta, cIdFiscaleAltro, cMess, cSql, cText, cTextWarning, nCurWA, oDO, oRec, oDitta, oRes, lIsTD28



** Non faccio controlli se è un autofattura, perchè questi vengono fatti nel metodo autotd_chk

**	Queste limitazioni valgono solo per le fatture elettroniche

If !Thisform.Fte_Isxml() 

	Return .T.

Endif



With ThisForm.PF.PGGenerale



nCurWA	= Select(0)

cScope	= Upper(Evl(cScope, 'SAVE'))

cText	= ''

cTextWarning	= ''



Do Case



	Case InList(cScope, 'CF', 'SAVE')

		cText	= ''



		oRec = xSQLExec2Obj('Select Top 1 * From Ditta')

		cIdFiscaleDitta = Nevl(Alltrim(oRec.Cd_Nazione)) + '|' + Nevl(Alltrim(oRec.PartitaIva), '')



		** Defect 224353

		**oDO = xSQLExec2Obj(Textmerge([Select FTE_AutoTipo, FTE_TipoDocumento = IsNull(FTE_TipoDocumento, 'TD01') From DO where Cd_DO = <<Format4Spt(DOTes.Cd_DO)>>]), .T.)

		oDO = xSQLExec2Obj(Textmerge([Select FTE_AutoTipo, FTE_TipoDocumento = (Case When TipoDocumento In ('F','A','N') And CliFor='C' And FTE_TipoDocumento Is Null Then 'TD01' Else '' End) From DO where Cd_DO = <<Format4Spt(DOTes.Cd_DO)>>]), .T.)

		

		cCd_CF		= Iif(oDO.FTE_AutoTipo = 2 And Not InList(oDO.FTE_TipoDocumento, 'TD21', 'TD27'), DOTes.Cd_CF_Auto, DOTes.Cd_CF)



		Text To cSql Noshow Textmerge

			Select IdFiscale = Rtrim(Upper(Coalesce(Cd_NazioneIva, Cd_Nazione, 'IT'))) + '|' + IsNull(Rtrim(PartitaIva), '')

				From CF

				Where Cd_CF = <<Format4Spt(cCd_CF)>>

		endtext

		cIdFiscaleAltro = xSqlExec2Var(cSql)

		

		** 00471

*		If InList(oDO.FTE_TipoDocumento, 'TD01', 'TD02', 'TD03', 'TD06', 'TD16', 'TD17', 'TD18', 'TD19', 'TD20', 'TD24', 'TD25', 'TD28')

		If InList(oDO.FTE_TipoDocumento, 'TD01', 'TD02', 'TD03', 'TD06', 'TD07', 'TD24', 'TD25')

			If cIdFiscaleDitta = cIdFiscaleAltro

				cTextWarning = This.TB_(,'698C342D-B95E-4081-B152-FCA97094C348', 'La tipologia di documento <%1!> prevede che Cedente e Cessionario siano diversi.', oDo.FTE_TipoDocumento)

			Endif		

		Endif

		

		** 00472

		If InList(oDO.FTE_TipoDocumento, 'TD21', 'TD27')

			If cIdFiscaleDitta <> cIdFiscaleAltro

				cTextWarning = cTextWarning + This.TB_(,'FB407CB9-F7EF-48B5-A2EE-47A86220920E', 'La tipologia di documento <%1!> prevede che Cedente e Cessionario coincidano.', oDo.FTE_TipoDocumento)

			Endif		

		Endif

		** 00476

		If Left(cIdFiscaleDitta, 3) <> 'IT|' And Left(cIdFiscaleAltro, 3) <> 'IT|'

			cTextWarning = cTextWarning + This.TB_(,'12A780D4-8C0A-44C4-98B3-BAAA423DFFB5', 'La tipologia di documento <%1!> prevede che almeno uno tra Cedente e Cessionario sia in Italia.', oDo.FTE_TipoDocumento)

		Endif		



**			** TD28 San Marino

**			If oDO.FTE_TipoDocumento = 'TD28' And Left(cIdFiscaleAltro, 3) <> 'SM|'

**				cText = cText + 	Thisform.TB_(,'8472214B-7001-42BE-8223-C85333E8FA17', ;

**										"L'anagrafica selezionata non risulta appartenente alla Repubblica di San Marino." + ;

**										Chr(13) + Chr(13) + "L'appartenenza è necessaria per i documenti ") + oRec.Cd_DO_TD

**			Endif

		

		** In caso di Warning segnalo al cambio e chiedo conferma prima della registrazione.

		If !Empty(cTextWarning)		

			cMess = 	Thisform.TB_(,"E79DC5DF-F43B-4812-B9BC-9A07D187BB2A", '** ATTENZIONE **') + Chr(13) + Chr(13) + cTextWarning + Chr(13) + Chr(13) ;

					+	Thisform.TB_(,"72314DD3-A3A6-4703-AF67-FDF20E3DBBBC", 'N.B.: con tale condizione il documento potrebbe essere scartato dal Sistema di Interscambio') ;

					+	Iif(cScope = 'SAVE', Chr(13) + Chr(13) + Thisform.TB_(,'E7BE48A0-41DA-4DBA-90AA-097720FF77AC','Confermi la registrazione?'), '')



			If cScope = 'SAVE'

				lRet = (xMessageBox(cMess, MB_IEYNDB2) = IDYES)

				If !lRet

					Return 0

				Endif					

			Else			

				xMessageBox( cMess, MB_ICONINFORMATION)		

			endif

		Endif



		If !Empty(cText)

			xMessageBox(Thisform.TB_(,"E79DC5DF-F43B-4812-B9BC-9A07D187BB2A", '** ATTENZIONE **') + Chr(13) + Chr(13) + cText, MB_ICONEXCLAMATION)

			Return 0

		EndIf



	Otherwise

	

		xMessagebox(Textmerge('Method FTE_CHECK : <<cScope>> not supported.'))

		

EndCase



EndWith



Select(nCurWA)



Return .T.

      

ENDPROC

PROCEDURE cmdftesend

Local nTop, nLeft, nRecNo



nTop  = This.Toolbar.Top + This.Toolbar.Height

nLeft = This.Toolbar.Buttons('FTESEND').Left



DOTes_InviaFatturaElettronica(Thisform, DoTes.Id_DoTes, nTop, nLeft)





ENDPROC

PROCEDURE cmdftelink



If FTE_Link('DOTes', DOTes.Id_DOTes, DOTes.Cd_CF, DOTes.FTE_CanModify)

	This.DE.MainCursor.RequeryCurrent()

	This.OnRecordChange()

EndIf  



ENDPROC

PROCEDURE sp_check

Local cText, lRet, oWA



oWA 	= SelectWA()

cText = ''

lRet 	= .T.



** ACQUISTI



If Bitand(DoTes.DOBitMask, TD_CP_DOCIVA) > 0



	** RIGHE

	

	Select Dorig



	** Verifico che non siano utilizzate aliquote con SPLIT SEPARATO in modo non corretto

	Scan For Iva_Split_Sep And (!IsEmpty(Cd_ReverseCharge) Or !IsEmpty(Dotes.Cd_ReverseCharge))

		cText = cText + Textmerge("- Riga <<Dorig.Riga>> : codice iva <<Dorig.Cd_Aliquota_r>>") + Chr(13)

	EndScan



	** SPESE

	

	Select Dorigspesa



	** Verifico che non siano utilizzate aliquote con SPLIT SEPARATO in modo non corretto

	Scan For Iva_Split_Sep And (!IsEmpty(Cd_ReverseCharge) Or !IsEmpty(Dotes.Cd_ReverseCharge))

		cText = cText + Textmerge("- Spesa <<Dorigspesa.Riga>> : codice iva <<Dorigspesa.Cd_Aliquota_r>>") + Chr(13)

	EndScan



	If !Empty(cText) 

		cText = 	"Presenza di codice IVA dedicato alla rilevazione dell'imposta in scissione da versare con tributo separato." + Chr(13) + Chr(13) + ;

					"Proseguendo verrà applicata inversione contabile anche alle righe di seguito elencate." + Chr(13) + Chr(13) + cText

	EndIf

	

EndIf



If !Empty(cText) And ;

	xMessageBox(Thisform.TB_(,'24378EDA-2911-4C26-A878-E750FDBF095F', cText + Chr(13) + "Proseguo ?"), MB_ICONEXCLAMATION + MB_YESNO + MB_DEFBUTTON2, oApp.AppName + ' * SCISSIONE PAGAMENTI *') = IDNO

																										

	lRet = .F.

	

EndIf



Return lRet



ENDPROC

PROCEDURE cmdfte_hubinspector

Local oForm



oForm = RunGeneric('Forms\Cmd_FTE.vcx', , 'HUBInspector_CA', DoTes.Id_DoTes)

If Vartype(oForm) = 'O'	

	oForm.Show(1)

	oForm.Release()

EndIf 

ENDPROC

PROCEDURE fte_autofattura

**	Local oDo



**	oDo = ThisForm.PF.pgGenerale.txtCd_DO.Field.FKRecord



** 0 - None

** 1 - Self Billing

** 2 - Integrazione / Autofattura

** 9 - Integrazione / Autofattura Old style (Fornitore duplicato come cliente)



**	nRet	= ICase(	;

**						oDo.FTE_AutoTipo = 1, 1, ;

**						oDo.FTE_AutoTipo = 2 And (Thisform.Mode != FEDIMODE_EDIT Or !ThisForm.PF.pgGenerale.txtCd_CF_Auto.Field.IsEmpty()), 2, ;

**						oDo.FTE_AutoTipo = 2 And Thisform.Mode = FEDIMODE_EDIT And ThisForm.PF.pgGenerale.txtCd_CF_Auto.Field.IsEmpty(), 9, ;

**						0 ;

**					 )

					

**	nRet	= ICase(	;

**						oDo.FTE_AutoTipo = 1, 1, ;

**						oDo.FTE_AutoTipo = 2 And (!IsEmpty(Substr(Dotes.Cd_Cf_Auto, 2)) Or Bitand(Thisform.Mode, FEDIMODE_INS_DUP) != 0), 2, ;

**						oDo.FTE_AutoTipo = 2 And IsEmpty(Substr(Dotes.Cd_Cf_Auto, 2)), 9, ;

**						0 ;

**					 )

Local nRet



** ATTENZIONE: Utilizando oDo invece che DoTes gli eventi non sembrano aggiornare correttamente i dati per cui in alcuni casi

** passando da fattura ad integrazione rimane il valore del cliente precedente.



nRet = Iif(Vartype(This.oFteXml) != 'O', 0, This.oFTEXML.GetAutoFatturaType(Dotes.FTE_AutoTipo, Dotes.Cd_Cf_Auto, Bitand(Thisform.Mode, FEDIMODE_INS_DUP) != 0))



Return nRet





ENDPROC

PROCEDURE fte_semplificata

Lparameters oDo



Local lRet



oDo 	= 	Iif(Type('oDo.Fte_TipoDocumento') == 'U', xSQlExec2Obj(Textmerge("Select * From DO Where Cd_DO = <<FormatC4SPT(Dotes.Cd_Do)>>"), .T.), oDo)

lRet 	= 	InList(Nvl(oDo.Fte_TipoDocumento, ''), 'TD07', 'TD08', 'TD09')



Return lRet



ENDPROC

PROCEDURE fte_notaiva

Return ThisForm.PF.pgGenerale.txtCd_DO.Field.FKRecord.Fte_NotaIva

ENDPROC

PROCEDURE extrainfo_load

** Extra Info

ExtraInfo_Load('DoTesExtraInfo', 'DoTes', Thisform.PF.pgGenerale.PF.pgInfo.cntExtraInfo, This.Mode = FEDIMODE_SHOW)

Thisform.PF.pgGenerale.PF.pgInfo.tltExtraInfo.Visible = (Thisform.PF.pgGenerale.PF.pgInfo.cntExtraInfo.Height > 0)

ObjDim(This.PF.pgGenerale.PF.pgInfo.cntAttributi,, Thisform.PF.pgGenerale.PF.pgInfo.cntExtraInfo.Bottom + 6)

ENDPROC

PROCEDURE cmdfteautotd

Lparameters lQuerySupported, nMess



If lQuerySupported



	**	TD_CP_DOCIVA -> Ciclo Passivo -> Per le fatture di acquisto che possono generare integrazione (ci pensa l'engine a decidere se ci sono i requisiti)

	**	TD_CA_DOCIVA -> Ciclo Attivo 	-> Per le fatture integrative dove viene permesso il ricalcolo (inutile complicazione ma possibile)



	Return Bitand(Dotes.DOBitMask, TD_CP_DOCIVA) != 0 And Vartype(This.oAutoTD) == 'O' And Thisform.Mode = FEDIMODE_SHOW

			

Endif



This.oAutoTD.Run_DOWS(Dotes.Id_Dotes, nMess, 0x0001)

This.AutoTD_Bar('RC')



ENDPROC

PROCEDURE autotd_set

** cScope -> nome simbolico per il do case



** xoldValue -> Passato soltanto nei casi in cui viene richiemato da qualche onvaluechange



Lparameters cScope, xoldValue



Local nCurWA, cAlias, oDo, oCF



With ThisForm.PF.PGGenerale



nCurWA	= Select(0)

cScope	= Upper(Evl(cScope, 'UI'))



** Devo essere sicuro che il valore dei field sia sincronizzato con il controlsource

** Il metodo e bindato con il PF.REFRESH()



oDO	= Iif(Type(".txtCd_DO.Field.FKRecord") == 'O', .txtCd_DO.Field.FKRecord, ;

				xSQLExec2Obj('Select Cd_DO, TipoDocumento, Clifor, FTE_TipoDocumento, FTE_Autotipo From DO Where Cd_Do = ' + FormatC4SPT(DoTes.Cd_Do), .T.))



oCF	= Iif(Type(".txtCd_CF_Auto.Field.FKRecord") == 'O', .txtCd_CF_Auto.Field.FKRecord, ;

				xSQLExec2Obj('Select Cd_CF, PartitaIva, CodiceFiscale From CF Where Cd_CF = ' + FormatC4SPT(DoTes.Cd_CF), .T.))



Do Case



	Case InList(cScope, 'UI')

	

		.txtCd_CF_Auto.Visible 	= (Thisform.FTE_Autofattura() = 2)

		.txtCd_CF.Visible 		= !.txtCd_CF_Auto.Visible

		

		** Defect 252769

		.txtCd_CF_Auto.Refresh()

		.txtCd_CF.Refresh()



		** No Cliente di fatturazione

		.PF.pgGenerale.txtCF_Fatt.Visible = !.txtCd_CF_Auto.Visible



		** Devo posizionare il campo fuori campo quando non visibile altrimenti si sovrappone al codice CF

		Iif(.txtCd_CF.Visible, ;

			ObjMov(.txtCd_CF_Auto, .txtCd_CF.Left - 100, .txtcd_CF.Top - 100), ;

			ObjMov(.txtCd_CF_Auto, .txtCd_CF.Left, .txtcd_CF.Top))

		

		**	Debugout 'AutoTD_Set() - 1.a'

		**	Debugout '.txtCd_CF_Auto.Field.IsEmpty()', 	.txtCd_CF_Auto.Field.IsEmpty()

		**	Debugout '.txtCd_CF_Auto.Field.Value', 		.txtCd_CF_Auto.Field.Value

		**	Debugout 'DOtes.Cd_Cf_Auto', DOtes.Cd_Cf_Auto		

		**	Debugout '.txtCd_CF_Auto.Visible', .txtCd_CF_Auto.Visible

		**	Debugout '.txtCd_CF.Visible', .txtCd_CF.Visible



		** Per qualche motivo che non si riesce a catturare con determinazione ogni modifica alla form sembra vada a modificare la sequenza di eventi e di refresh del campo Cd_CF_Auto

		** che in alcune condizioni presenta il controlsource (DOTES.Cd_CF_Auto) non allineato con il value del text invalidando il recupero del record in FKRECORD_ACCESS

		** Iif(.txtCd_CF_Auto.Field.IsEmpty() And .txtCd_CF_Auto.Visible, .txtCd_CF_Auto.Field.Refresh(), .T.)



		**	Debugout 'AutoTD_Set() - 1.b'

		**	Debugout '.txtCd_CF_Auto.Field.IsEmpty()', 	.txtCd_CF_Auto.Field.IsEmpty()

		**	Debugout '.txtCd_CF_Auto.Field.Value', 		.txtCd_CF_Auto.Field.Value

		**	Debugout 'DOtes.Cd_Cf_Auto', DOtes.Cd_Cf_Auto		

		**	Debugout '.txtCd_CF_Auto.Visible', .txtCd_CF_Auto.Visible

		**	Debugout '.txtCd_CF.Visible', .txtCd_CF.Visible



	Case InList(cScope, 'UICOLS')



		** Sono pagine dinamiche per cui non ho garanzia che le grid esistano



		** Se c'è un codice in testa non si vedono le righe perché prevale su tutto

		** Il codice si può cambiare soltanto per il ciclo passivo in presenza di aliquote libere (senza codice in anagrafica)



		If PemStatus(.PF.pgRighe, 'Cnt', 5)

			.PF.pgRighe.Cnt.Grid.ColCd_ReverseCharge.Visible = (IsEmpty(DoTes.Cd_ReverseCharge))

			.PF.pgRighe.Cnt.Grid.ColCd_ReverseCharge.Enabled = (IsEmpty(Dotes.Cd_ReverseCharge) And Dotes.Clifor == 'F')

		EndIf

		

		If PemStatus(.PF.pgPiede, 'Cnt', 5)

			.PF.pgPiede.Cnt.cntFattura.Grid.ColCd_ReverseCharge.Visible = (IsEmpty(DoTes.Cd_ReverseCharge))

			.PF.pgPiede.Cnt.cntFattura.Grid.ColCd_ReverseCharge.Enabled	= (IsEmpty(Dotes.Cd_ReverseCharge) And Dotes.Clifor == 'F')

		EndIf



	** ------------------------------------------------------------



	Case InList(cScope, 'DO')

	

		Thisform.AutoTD_Set('UI')

		

		If Thisform.FTE_Autofattura() = 2

			Local cCd_CF_Auto

			** Imposto il cessionario che è nascosto (Cd_CF) ed è il cliente che rappresenta la ditta

			

			cCd_CF_Auto = xSQlExec2var('Select Dbo.afn_CF_Ditta()')

			If !IsEmpty(cCd_CF_Auto) 

				.txtCd_CF.Field.SetValue(cCd_CF_Auto)

			endif

			** Imposto il CC (almeno finché l'hub non viene sistemato)

			**	cAlias = This.oFteXml.Alias_TDOC

			**	This.oFteXml.TDoc_XMLToCursor(Dotes.Fte_Xml)



			**	If IsEmpty(&cAlias..EM_SoggettoEmittente)

			**		Replace EM_SoggettoEmittente With 'CC' In (cAlias)

			**		Replace FTE_Xml With This.oFtexml.TDoc_CursorToXML() In Dotes

			**	EndIf



			**	This.oFtexml.TDoc_WA_Destroy()



		EndIf

		

	Otherwise

	

		xMessagebox(Textmerge('Method AUTOTD : <<cScope>> not supported.'))

		

EndCase



EndWith



Select(nCurWA)



ENDPROC

PROCEDURE autotd_chk

** cScope -> nome simbolico per il do case



Lparameters cScope



Local cAlias, cCd_CF, cIdFiscaleDitta, cIdFiscaleAltro, cSql, cText, cTextWarning, nCurWA, oDO, oRec, oDitta, oRes, lIsTD28



With ThisForm.PF.PGGenerale



** Valido soltanto per documenti integrativi secondo il nuovo formato

If Thisform.FTE_Autofattura() != 2

	Return .T.

EndIf



nCurWA	= Select(0)

cScope	= Upper(Evl(cScope, 'SAVE'))

cText	= ''

cTextWarning	= ''



Do Case



	Case InList(cScope, 'SAVE')



	cText = ''



	If Thisform.oAutoTD.CF_Count() = 0

		cText = This.TB_(,'E339D8B3-9561-46A9-A8FC-CBBD6766F03A', 'Per continuare è necessario creare una anagrafica corrispondente ai dati aziendali.')			

		Return This.AutoTD_Chk('DO')			

	Endif



	If Vartype(This.oFteXml) == 'O'



		cAlias = This.oFteXML.TDoc_XMLToCursor(Dotes.fte_xml)

		If !IsEmpty(cAlias) And (IsEmpty(&cAlias..FC_IdDocumento) Or IsEmpty(&cAlias..FC_Data))

			cText = cText + Thisform.TB_(,'98226824-CDFA-44A7-8715-E6EDE5674AD0', "- La compilazione di un documento integrativo potrebbe richiedere l'indicazione del numero e data della fattura collegata.") + Chr(13)

		EndIf

		This.oFtexml.TDOC_WA_Destroy()

	

	EndIf

	

	** Message UI

	If !Empty(cText) 



		cText =	Thisform.TB_(,'222A6DFA-D6B5-47FC-A8DB-5AB8CC6F0E4B', "ATTENZIONE! Verificare le seguenti condizioni: ") + Chr(13) + Chr(13) + ;

					cText + Chr(13) + ;

					Thisform.TB_(,'325BBB30-09A5-487E-A448-3C28A1E475CF', "Continuo?")

		

		If xMessageBox(cText, MB_ICONQUESTION + MB_YESNO) = IDNO

			Return .F.

		EndIf

		

	EndIf



		* Controllo la presenza di righe non definite come beni, perchè nel TD28 sono accettati solo quelli

		* Se non è definita la tipologia in AL e in AR considero la riga come servizio

		*	TipoBeneServizio	= Coalesce(Nullif(AL.TipoBeneServizio, ''), Nullif(AR.IntraTipo, ''), 'S')

		

		cFTE_TipoDocumento = xSQLExec2Var(Textmerge([Select FTE_TipoDocumento = IsNull(FTE_TipoDocumento, 'TD01') From DO where Cd_DO = <<Format4Spt(DOTes.Cd_DO)>>]))

		If cFTE_TipoDocumento = 'TD28'

			Local nRecNoBeni

			Select Cd_AR, Cd_Aliquota From DORig With (Buffering = .T.) Where PrezzoTotaleV <> 0 Into Cursor crRig

			cCursName = ''

			CursorToServer('crRig', @cCursName)

			Text To cSql Noshow Textmerge

				Select RigheBeni	= Sum(Case when TipoBeneServizio = 'B' THEN 1 ELSE 0 END)

						,RigheNoBeni= Sum(Case when TipoBeneServizio = 'B' THEN 0 ELSE 1 END)

				From 	(

						Select	crRig.Cd_AR

								 , crRig.Cd_Aliquota

								 , TipoBeneServizio	= Coalesce(Nullif(AL.TipoBeneServizio, ''), Nullif(AR.IntraTipo, ''), 'S')

							From <<cCursName>>	crRig

							Left Join AR 				On crRig.Cd_AR		= AR.Cd_AR

							Left Join Aliquota AL	On crRig.Cd_Aliquota	= AL.Cd_Aliquota )

					crRes

			endtext

			oRes = xSqlExec2Obj(cSql)

			If oRes.RigheNoBeni > 0

				Text To cText Noshow Pretext 2

					La tipologia di documento %1! prevede che tutte le righe siano contrassegnate come Beni.

				endtext



				cTextWarning = cTextWarning + This.TB_(,'7AD0211F-87C0-4BD1-988A-8283176BA9E7', cText, cFTE_TipoDocumento)

				xMessageBox(cTextWarning, MB_ICONEXCLAMATION)

			endif

		Endif





	Case InList(cScope, 'DO')

		cText	= ''



		oRec = xSQLExec2Obj('Select Top 1 * From Ditta')

		

		** Prima di effettuare i controlli di validità provvedo a verificare l'esistenza del cliente ditta ed eventualmente guidare l'utente nella creazione

		Thisform.oAutoTD.CF_Set()

	

		cText = cText + 	Iif(Thisform.oAutoTD.CF_Count() = 0, Thisform.TB_(,'8472214B-7001-42BE-8223-C85333E8FA17', ;

								Textmerge("Non è stata rilevata alcuna anagrafica corrispondente ai dati aziendali:") + ;

								Iif(!IsEmpty(oRec.PartitaIva), 		Textmerge(Chr(13) + 'PI : <<Alltrim(oRec.PartitaIva)>>'), '') + ;

								Iif(!IsEmpty(oRec.CodiceFiscale), 	Textmerge(Chr(13) + 'CF : <<Alltrim(oRec.CodiceFiscale)>>'), '') + ;

								Chr(13) + Chr(13) + "L'operazione risulta necessaria per l'utilizzo dei documenti integrativi."), '')



		If !Empty(cText)		



			xMessageBox(Thisform.TB_(,"E79DC5DF-F43B-4812-B9BC-9A07D187BB2A", '** ATTENZIONE **') + Chr(13) + Chr(13) + cText, MB_ICONEXCLAMATION)

			Return 0



		EndIf



	Case InList(cScope, 'CF_AUTO', 'CF_AUTO4SAVE')

		cText	= ''



		If Thisform.oAutoTD.CF_Count() = 0

			cText = This.TB_(,'E339D8B3-9561-46A9-A8FC-CBBD6766F03A', 'Per continuare è necessario creare una anagrafica corrispondente ai dati aziendali.')			

			Return This.AutoTD_Chk('DO')			

		Endif

		

		oRec = xSQLExec2Obj('Select Top 1 * From Ditta')

		cIdFiscaleDitta = Nvl(Alltrim(oRec.Cd_Nazione), '') + '|' + Nvl(Alltrim(oRec.PartitaIva), '')



		* Di default considero FTE_TipoDocumento = 'TD01'

		oDO = xSQLExec2Obj(Textmerge([Select FTE_AutoTipo, FTE_TipoDocumento = IsNull(FTE_TipoDocumento, 'TD01') From DO where Cd_DO = <<Format4Spt(DOTes.Cd_DO)>>]), .T.)

		cCd_CF		= Iif(oDO.FTE_AutoTipo = 2, DOTes.Cd_CF_Auto, DOTes.Cd_CF)



		Text To cSql Noshow Textmerge

			Select IdFiscale = Rtrim(Upper(Coalesce(Cd_NazioneIva, Cd_Nazione, 'IT'))) + '|' + IsNull(Rtrim(PartitaIva), '')

				From CF

				Where Cd_CF = <<Format4Spt(cCd_CF)>>

		endtext

		cIdFiscaleAltro = xSqlExec2Var(cSql)

		

		** 00471

*		If InList(oDO.FTE_TipoDocumento, 'TD01', 'TD02', 'TD03', 'TD06', 'TD16', 'TD17', 'TD18', 'TD19', 'TD20', 'TD24', 'TD25', 'TD28')

		If InList(oDO.FTE_TipoDocumento, 'TD16', 'TD17', 'TD18', 'TD19', 'TD20', 'TD22', 'TD23', 'TD28', 'TD29')

			If cIdFiscaleDitta = cIdFiscaleAltro

				cTextWarning = This.TB_(,'698C342D-B95E-4081-B152-FCA97094C348', 'La tipologia di documento <%1!> prevede che Cedente e Cessionario siano diversi.', oDo.FTE_TipoDocumento)

			Endif		

		Endif

		

		** 00472

**			If InList(oDO.FTE_TipoDocumento, 'TD21', 'TD27')

**				If cIdFiscaleDitta <> cIdFiscaleAltro

**					cText = This.TB_(,'FB407CB9-F7EF-48B5-A2EE-47A86220920E', 'La tipologia di documento <%1!> prevede che Cedente e Cessionario coincidano.', oDo.FTE_TipoDocumento)

**				Endif		

**			Endif



**			** 00476

		If Left(cIdFiscaleDitta, 3) <> 'IT|' And Left(cIdFiscaleAltro, 3) <> 'IT|'

			cTextWarning = cTextWarning + This.TB_(,'12A780D4-8C0A-44C4-98B3-BAAA423DFFB5', 'La tipologia di documento <%1!> prevede che almeno uno tra Cedente e Cessionario sia in Italia.', oDo.FTE_TipoDocumento)

		Endif		



		** TD28 San Marino

*!*			If Nvl(oDO.FTE_TipoDocumento, '') = 'TD28' And Left(cIdFiscaleAltro, 3) <> 'SM|'

*!*				cText = cText + 	Thisform.TB_(,'8472214B-7001-42BE-8223-C85333E8FA17', ;

*!*										"L'anagrafica selezionata non risulta appartenente alla Repubblica di San Marino." + ;

*!*										Chr(13) + Chr(13) + "L'appartenenza è necessaria per i documenti ") + oDO.FTE_TipoDocumento

*!*			Endif



		** TD28 San Marino | Soggetti non stabiliti, ancorché identificati in Italia

		Local cCd_Naz

		cCd_Naz = xSqlExec2Var(Textmerge('Select Cd_Nazione From CF Where Cd_CF = <<FormatC4spt(cCd_CF)>>'))



		If Nvl(oDO.FTE_TipoDocumento, '') == 'TD28' And cCd_Naz == 'IT'	

			cText = cText +	Thisform.TB_(,'C8F7E9A5-2180-4DBD-BE9B-FC8013E2997A', ;

							"Il documento TD28 può essere predisposto per operazioni con fornitori residenti nella repubblica di San Marino " + ;

							"o non stabiliti, ancorché identificati in Italia." + Chr(13) + Chr(13) + ;

							"Si consiglia di verificare la nazione attribuita nell'anagrafica del soggetto '") + cCd_CF + "'"

		EndIf

			

		** In caso di Warning segnalo al cambio e chiedo conferma prima della registrazione.

		If !Empty(cTextWarning)		

			cMess = 	Thisform.TB_(,"E79DC5DF-F43B-4812-B9BC-9A07D187BB2A", '** ATTENZIONE **') + Chr(13) + Chr(13) + cTextWarning + Chr(13) + Chr(13) ;

					+	Thisform.TB_(,"72314DD3-A3A6-4703-AF67-FDF20E3DBBBC", 'N.B.: con tale condizione il documento potrebbe essere scartato dal Sistema di Interscambio') ;

					+	Iif(cScope == 'CF_AUTO4SAVE',  Chr(13) + Chr(13) + Thisform.TB_(,'E7BE48A0-41DA-4DBA-90AA-097720FF77AC','Confermi la registrazione?'), '')



			If cScope == 'CF_AUTO4SAVE'

				lRet = (xMessageBox(cMess, MB_IEYNDB2) = IDYES)

				If !lRet

					Return 0

				Endif				

			Else			

				xMessageBox(cMess, MB_ICONINFORMATION)

			Endif

		Endif



		If !Empty(cText)		

			xMessageBox(Thisform.TB_(,"E79DC5DF-F43B-4812-B9BC-9A07D187BB2A", '** ATTENZIONE **') + Chr(13) + Chr(13) + cText, MB_ICONEXCLAMATION)

			Return 0

		EndIf



	Case InList(cScope, 'AR')



		** Verifico se l'articolo è configurato come bene/servizio in accordo con il tipodocumento

		

	Case InList(cScope, 'IVA')

	

		Debugout 'IVA'



	Otherwise

	

		xMessagebox(Textmerge('Method AUTOTD : <<cScope>> not supported.'))

		

EndCase



EndWith



Select(nCurWA)

      

ENDPROC

PROCEDURE autotd_init

With ThisForm.PF.pgGenerale



** A fianco del CF (ditta) al posto della SO

**	ObjMov(.txtCd_CF_Auto, .txtCFDest.Left, .txtCFDest.Top)

**	.txtCd_CF_Auto.TabIndex = .txtCFDest.TabIndex



** Al posto del CF

ObjMov(.txtCd_CF_Auto, .txtCd_CF.Left, .txtcd_CF.Top)

.txtCd_CF_Auto.TabIndex = ThisForm.PF.pgGenerale.txtCd_CF.TabIndex



EndWith



ENDPROC

PROCEDURE show_riga

Local lRet



lRet = .F.



Do Case



	Case !IsEmpty(This.ShowId_DoRig)



		This.CmdPGGenerale()

		This.PF.pgGenerale.PF.ActivePage = This.PF.pgGenerale.PF.pgRighe.PageOrder

		This.PF.PGElenco.Enabled 					= .F.

		This.Toolbar.Buttons('NEW').Visible  	= .F.



		lRet = .T.



	Case !IsEmpty(This.ShowId_DoRigSpesa)



		This.CmdPGGenerale()

		This.PF.pgGenerale.PF.ActivePage = This.PF.pgGenerale.PF.pgPiede.PageOrder

		This.PF.PGElenco.Enabled 					= .F.

		This.Toolbar.Buttons('NEW').Visible  	= .F.



		lRet = .T.



EndCase



Return lRet



ENDPROC

PROCEDURE cmdfteautotdview

Lparameters lQuerySupported



Local lRet, oRun



** Visibile nella fattura di acquisto e visualizza il documento integrativo collegato



If lQuerySupported



	**	TD_CP_DOCIVA -> Ciclo Passivo -> Per le fatture di acquisto che possono generare integrazione (ci pensa l'engine a decidere se ci sono i requisiti)

	**	TD_CA_DOCIVA -> Ciclo Attivo 	-> Per le fatture integrative dove viene permesso il ricalcolo (inutile complicazione ma possibile)



	Return Bitand(Dotes.DOBitMask, TD_CP_DOCIVA) != 0 And Vartype(This.oAutoTD) == 'O' And This.oAutoTD.Exists_Auto(Dotes.Id_Dotes)

			

Endif



This.oAutoTD.View_Auto(Dotes.Id_Dotes)



ENDPROC

PROCEDURE cmdfteautotdfatt

Lparameters lQuerySupported



** Visibile nel documento integrativo e visualizza la fattura di acquisto da cui deriva



If lQuerySupported



	**	TD_CP_DOCIVA -> Ciclo Passivo -> Per le fatture di acquisto che possono generare integrazione (ci pensa l'engine a decidere se ci sono i requisiti)

	**	TD_CA_DOCIVA -> Ciclo Attivo 	-> Per le fatture integrative dove viene permesso il ricalcolo (inutile complicazione ma possibile)



	Return Vartype(This.oAutoTD) == 'O' And !IsEmpty(Dotes.Id_Dotes_P_Fatt)

			

Endif



Iif(Thisform.Toolbar.IsPresent('FTEAUTOTDFATT') And Thisform.Toolbar.Buttons('FTEAUTOTDFATT').ButtonMenus('FTEAUTOTDFATT').Enabled, This.oAutoTD.View_Fatt(Dotes.Id_Dotes), Thisform.CmdfteAutoTdCoge())



ENDPROC

PROCEDURE autotd_bar

Lparameters cScope



Local oBtn, i



cScope = Upper(NEvl(cScope, ''))



With Thisform.Toolbar



	Do Case



		** Init Toolbar

		Case cScope = 'TB'



			** Creo sempre tutti i pulsanti in modo che ci siano anche in tutti i documenti, poi ci pensa il QuerySupport a visualizzar in base alle caratteristiche del record

			i = .Buttons('FTEXML').Index + 1



			** Visibile se NON c'è un doc collegato

			oBtn = .Buttons.Add(i, 'FTEAUTOTD',	, 0, 'AUTOTD')

			oBtn.ToolTipText 	= TT_(, "DD02BD8D-14DA-4919-84CD-E8B02C9AB2B9", 'Genera Integrazione compensativa.')

			oBtn.Visible 		= .F.

			i = i + 1



			** Visibile se c'è un doc collegato

			oBtn = .Buttons.Add(i, 'FTEAUTOTDEX', , 5, 'AUTOTD')

			oBtn.ToolTipText 	= TT_(, "DD02BD8D-14DA-4919-84CD-E8B02C9AB2B9", 'Genera Integrazione compensativa.')

			oBtn.ButtonMenus.Add(, 'FTEAUTOTD', 		TM_(, "DD02BD8D-14DA-4919-84CD-E8B02C9AB2B9", 'Genera Integrazione compensativa'))

			oBtn.ButtonMenus.Add(, 'FTEAUTOTDVIEW', 	TM_(, "9F1550D1-EE28-4E5E-B531-191E05A5DCA0", 'Visualizza il documento integrativo'))

			oBtn.Visible 		= .F.

			i = i + 1



			** Visibile se c'è una fattura collegata (id_dotes_P_fatt)

			oBtn = .Buttons.Add(i, 'FTEAUTOTDFATT', , 5, 'AUTOTD')

			oBtn.ToolTipText 	= TT_(, "335BECD8-E5F9-4FAB-BF01-CDAEBAD3CCDF", 'Visualizza la fattura di acquisto collegata.')

			oBtn.ButtonMenus.Add(, 'FTEAUTOTDFATT', 	TM_(, "335BECD8-E5F9-4FAB-BF01-CDAEBAD3CCDF", 'Visualizza la fattura di acquisto collegata'))



			If oApp.LicInfo.CG_Main

				oBtn.ButtonMenus.Add(, 'FTEAUTOTDCOGE', TM_(, "4AFAB6F8-DE8C-4028-9377-F34B81603B71", 'Visualizza la cessione compensativa contabile'))

			Endif



			oBtn.Visible 		= .F.



		** OnRecordChange()

		Case cScope = 'RC'



			If Thisform.CmdFteAutoTDView(.T.)



				If .IsPresent('FTEAUTOTD')

					.Buttons('FTEAUTOTD').Visible = .F.

				Endif



				If .IsPresent('FTEAUTOTDEX')

					.Buttons('FTEAUTOTDEX').Visible = .T.

					.Buttons('FTEAUTOTDEX').ButtonMenus('FTEAUTOTD').Enabled = Thisform.CmdFteAutoTD(.T.)

				Endif



			Else



				If .IsPresent('FTEAUTOTD')

					.Buttons('FTEAUTOTD').Visible = Thisform.CmdFteAutoTD(.T.)

				Endif



				If .IsPresent('FTEAUTOTDEX')

					.Buttons('FTEAUTOTDEX').Visible = .F.

				Endif



			Endif



			If .IsPresent('FTEAUTOTDFATT')

				.Buttons('FTEAUTOTDFATT').Visible = Thisform.CmdFteAutoTDFatt(.T.)

				If oApp.LicInfo.CG_Main

					.Buttons('FTEAUTOTDFATT').ButtonMenus('FTEAUTOTDCOGE').Enabled = Thisform.CmdFteAutoTDCoge(.T.)

				EndIf 

			Endif



		** OnModeChange()

		Case cScope = 'MC'



			This.Autotd_bar('RC')



	Endcase



Endwith



ENDPROC

PROCEDURE cmdfteautotdex

This.CmdfteAutoTD()

ENDPROC

PROCEDURE cmdfteautotdcoge

Lparameters lQuerySupported



** Visibile nel documento integrativo e visualizza la fattura di acquisto da cui deriva



If lQuerySupported



	**	TD_CP_DOCIVA -> Ciclo Passivo -> Per le fatture di acquisto che possono generare integrazione (ci pensa l'engine a decidere se ci sono i requisiti)

	**	TD_CA_DOCIVA -> Ciclo Attivo 	-> Per le fatture integrative dove viene permesso il ricalcolo (inutile complicazione ma possibile)



	Return Vartype(This.oAutoTD) == 'O' And !IsEmpty(Dotes.Id_Dotes_P_Fatt)

			

Endif



This.oAutoTD.View_Coge(Dotes.Id_Dotes)



ENDPROC

PROCEDURE ndoccomm_check



Local lRet, _cAlias_XX, _cAlias_YY, cText, nRighe, nRigheTot, cTipoDato 



lRet 	= .T.



** Solo per le Elettroniche

If DoTes.FatturaElettronica



	_cAlias_XX = GetUniqueName()

	_cAlias_YY = GetUniqueName()

	nRighe	   = 0

	nRigheTot  = 0

	cText	   = ''



	**AddProperty(This, 'oFTEXML', NewObject('FTEXML_Document_Engine', 'Forms\FTE_Writer.fxp'))



	** Verifico che siano presenti righe miste: con N.DOC.COMM e senza in Altri Dati gestionali

	Select DoRig

	Scan

		If DoRig.PrezzoTotaleV <> 0 And DoRig.Qta <> 0 

			This.oFTEXML.RDoc_XMLToCursor(DoRig.FTE_Xml, _cAlias_XX)

			This.oFTEXML.RDoc_1_XMLToCursor(&_cAlias_XX..DG_AltriDatiGestionali, _cAlias_YY)

			cTipoDato = &_cAlias_YY..TipoDato

			If InList(Upper(cTipoDato), "N.DOC.COMM","N.RICEVUTA","N.SCONTRIN")

				nRighe = nRighe + 1

				** Verifico che Aliquota ha impostato (deve avere Liquidazione = 0)

				If xSqlExec2Var("Select Liquidazione From Aliquota Where Cd_Aliquota = "+Format4Spt(DoRig.Cd_Aliquota))  

					cText = cText + Textmerge('- Riga <<DoRig.Riga>> con Aliquota Iva <<Alltrim(DoRig.Cd_Aliquota)>> non coerente perchè inclusa in Liquidazione') + Chr(13)

				EndIf 			

			EndIf

			nRigheTot =  nRigheTot + 1

		EndIf

	EndScan



	** Se le righe con N.DOC.COMM sono tutte le righe documento e hanno Aliquota non inclusa in liquidazione (vedi cText), allora il movimento contabile va impostato con il check "operazione non valida ai fini della liquidazione iva".

	If nRighe = nRigheTot 

		** nella asp_Do_End verrà messo CGMovT.NoLiquidazione=1 --> messaggio che il movimento non andrà in liquidazione

		xMessageBox(Thisform.TB_(,'91368617-0778-49BA-ABBC-AD579304FC15', "La registrazione contabile del documento verrà esclusa dalla liquidazione iva"),MB_ICONQUESTION)

	Else

		** Se le righe sono miste allora devo verificare che l'aliquota usata nelle righe con N.DOC.COMM abbia Aliquota.Liquidazione=0... altrimenti blocco il salvataggio

		If !IsEmpty(cText) 

			xMessageBox(Thisform.TB_(,'91368617-0778-49BA-ABBC-AD579304FC15', "Rilevata incongruenza tra i dati inseriti in Altri Dati Gestionali della Fattura Elettronica e Aliquote Iva" + Chr(13) + Chr(13) + cText),MB_ICONSTOP)

			lRet = .F.		

		EndIf

				

	EndIf

EndIf

	

Go Top In DoRig

Return lRet



ENDPROC

PROCEDURE checkfifocontinuo

Local cText, lRet, nSavedRec, oRec, oWA



If DoTes.Esecutivo = .F.

	** Se il documento che sto registrando non sarà esecutivo

	Return .T.

EndIf



oRec = This.PF.pgGenerale.txtCd_Do.Field.FKRecord

If Not InList(oRec.TipoDocumento, 'M') 		;	&& Se non è un documento di reso merce 

	Or Not oRec.FFC_MostraRiferimentoCarico 	;	&& Se non mostra la colonna di riferimento del reso

	Or Not xSqlExec2Var(Textmerge('Select CSFlag From MGCausale Where Cd_MGCausale = <<FormatC4SPT(oRec.Cd_MGCausale)>>'))

															&& Se la causale non movimenta magazzini 	

	Return .T.

Endif	



oWA 	= SelectWA('Dorig')

cText	= ''

lRet	= .T.



Scan For !IsEmpty(Cd_AR) And !IsEmpty(Qta) And IsEmpty(Id_MGMov_Carico)

	

	cText = cText + Thisform.TB_(,'6EBFCDD8-4C91-45A6-9F4B-65C19D399C97','Riferimento id carico non indicato nella riga ') + Transform(DoRig.Riga) + Chr(13)



EndScan



If !Empty(cText) And xMessageBox(cText + Chr(13) + Chr(13) + Thisform.TB_(,'EAC73160-F9EC-48D9-ACFD-12065559E482', 'Proseguo ?'), MB_ICONEXCLAMATION + MB_YESNO + MB_DEFBUTTON2) = IDNO

	lRet = .F.

EndIf



Return lRet  

ENDPROC

PROCEDURE cmdprinttopassportrol

With ThisForm.PF.pgGenerale.PF

	If .pgModuli.ControlCount = 0

		.DynamicPageInit(.pgModuli)

		.pgModuli.Refresh()

	EndIf

EndWith



DoDefault()



ENDPROC

PROCEDURE cmdprinttopassportlol

With ThisForm.PF.pgGenerale.PF

	If .pgModuli.ControlCount = 0

		.DynamicPageInit(.pgModuli)

		.pgModuli.Refresh()

	EndIf

EndWith



DoDefault()



ENDPROC

PROCEDURE cmdprinttopassportfax

With ThisForm.PF.pgGenerale.PF

	If .pgModuli.ControlCount = 0

		.DynamicPageInit(.pgModuli)

		.pgModuli.Refresh()

	EndIf

EndWith



DoDefault()



ENDPROC

PROCEDURE loadde

DoDefault()

AddProperty(This, 'oMatricole', 	NewObject0('C_MatricoleDoRigHlpr', ''))

AddProperty(This, 'oFTEXML', 		NewObject('FTEXML_Document_Engine', 'Forms\FTE_Writer.fxp'))

ENDPROC

PROCEDURE cmdeditrec

LParameters lFromDetailForm



Local oControl



If Type('ThisForm.ActiveControl') != 'O'

	Return

EndIf

oControl = ThisForm.ActiveControl



If oControl.IsA('grddoreport')

	oControl.cmdEditRec()

	Return

EndIf



ENDPROC

PROCEDURE cmdprinttotxt

With ThisForm.PF.pgGenerale.PF

	If .pgModuli.ControlCount = 0

		.DynamicPageInit(.pgModuli)

		.pgModuli.Refresh()

	EndIf

EndWith



DoDefault()



ENDPROC

PROCEDURE cmdprinttortf

With ThisForm.PF.pgGenerale.PF

	If .pgModuli.ControlCount = 0

		.DynamicPageInit(.pgModuli)

		.pgModuli.Refresh()

	EndIf

EndWith



DoDefault()



ENDPROC

PROCEDURE cmdprinttopdf

With ThisForm.PF.pgGenerale.PF

	If .pgModuli.ControlCount = 0

		.DynamicPageInit(.pgModuli)

		.pgModuli.Refresh()

	EndIf

EndWith



DoDefault()



ENDPROC

PROCEDURE cmdprinttohtm

With ThisForm.PF.pgGenerale.PF

	If .pgModuli.ControlCount = 0

		.DynamicPageInit(.pgModuli)

		.pgModuli.Refresh()

	EndIf

EndWith



DoDefault()



ENDPROC

PROCEDURE cmdprinttoemail

With ThisForm.PF.pgGenerale.PF

	If .pgModuli.ControlCount = 0

		.DynamicPageInit(.pgModuli)

		.pgModuli.Refresh()

	EndIf

EndWith



DoDefault()



ENDPROC

PROCEDURE cmdprinttobin

With ThisForm.PF.pgGenerale.PF

	If .pgModuli.ControlCount = 0

		.DynamicPageInit(.pgModuli)

		.pgModuli.Refresh()

	EndIf

EndWith



DoDefault()



ENDPROC

PROCEDURE mnu_initviewpad

LPARAMETERS cKey



#DEFINE MB_VIEW_SEP_1  		1000

#DEFINE MB_VIEW_SCADENZA 	1001		&& Analoga costante in mnu_Enabler

#DEFINE MB_VIEW_INTRA 		1002		&& Analoga costante in mnu_Enabler

#DEFINE MB_VIEW_CG	 		1003		&& Analoga costante in mnu_Enabler

#DEFINE MB_VIEW_FTEXML 		1004		&& Analoga costante in mnu_Enabler



LOCAL cMenuName, cPopupName, cForm



DODEFAULT(cKey)



WITH This

	cForm			= .Name

	cMenuName 	= .mnu_GetMenuName ()

	cPopupName 	= .mnu_GetPopupName(cKey)

ENDWITH



DEFINE BAR MB_VIEW_SEP_1 		OF (cPopupName) PROMPT "\-"

DEFINE BAR MB_VIEW_SCADENZA 	OF (cPopupName) PROMPT Thisform.TM_(,"32AA2C9F-6D5A-45D9-8EED-8358F8C0E7B5", "Scadenze") SKIP FOR !&cForm..Toolbar.IsActive('VIEWSCADENZA')

ON SELECTION BAR MB_VIEW_SCADENZA 	OF (cPopupName) &cForm..DoCmd('VIEWSCADENZA')



If oApp.Licinfo.CG_Main

	DEFINE BAR MB_VIEW_INTRA 				OF (cPopupName) PROMPT Thisform.TM_(,"7A80706D-8AA4-48B8-B537-B2C4F7FF58CA", "Intra")			SKIP FOR !&cForm..Toolbar.IsActive('VIEWINTRA')

	DEFINE BAR MB_VIEW_CG 					OF (cPopupName) PROMPT Thisform.TM_(,"05124739-4DE0-454F-B932-1B1201893B4C", "Contabilità")	SKIP FOR !&cForm..Toolbar.IsActive('VIEWCG')

	ON SELECTION BAR MB_VIEW_INTRA 		OF (cPopupName) &cForm..DoCmd('VIEWINTRA')

	ON SELECTION BAR MB_VIEW_CG 			OF (cPopupName) &cForm..DoCmd('VIEWCG')

EndIf



If oApp.LicInfo.FatturaElettronica Or oApp.LicInfo.FatturaElettronicaPassiva

	DEFINE BAR  MB_VIEW_FTEXML	OF (cPopupName) PROMPT Thisform.TM_(,"315C0B9E-3D09-4D2B-A952-FD22B4D0DDBC", "Dati aggiuntivi Fattura Elettronica") SKIP FOR !&cForm..Toolbar.IsActive('FTEXML')

	ON SELECTION BAR  MB_VIEW_FTEXML	OF (cPopupName) &cForm..DoCmd('FTEXML')	

EndIf 



RETURN cPopupName

ENDPROC

PROCEDURE save

LParameters lInsertMode



Local lRet, oMgMovForm, nOldWA



** Spostato sul server (asp_do_end + asp_do_ftexml)

** This.Fte_Save()



** Salvo il record prima dell'update per confrontare eventuali oldval dopo l'update (Vedi LinkManager)

AddProperty(This.De.DOTes, 'Old', xSQLExec2obj(This.De.DOTes.BuildRequeryCurrentStmt(), .T.))



** Salvo i valori dei campi EXTRA

ExtraInfo_Save('DOTES', This.PF.pgGenerale.PF.pgInfo.cntExtrainfo)



lRet = DoDefault(lInsertMode)



If lRet



	Local oMgMovDocForm , oCausaleInfo, lDoUIMgMovEdit 

	

	lDoUIMgMovEdit = ThisForm.PF.pgGenerale.txtCd_DO.Field.fkRecord.UIMgMovEdit And ((oApp.LicInfo.MG_Main And oApp.LicInfo.DO_LottiMatr) Or oApp.LicInfo.MG_Main)

	

	If lInsertMode	

		** Salvo i dati della testa documento per riproporli al prossimo inserimento (vedi metodo .cmdNew)

		nOldWA = Select(0)

		Select DoTes

		Scatter Name This.oRecPrev Memo 

		Select (nOldWA)		

	EndIf 

	

	If lDoUIMgMovEdit

	

		** Faccio anche un check che la causale movimenti effettivamente i componenti

	

		oCausaleInfo = xSqlExec2Obj("SELECT Convert(Bit, Count(*)) As MovimentaComponenti " + ;

								"FROM DO JOIN MGCausale ON MGCausale.Cd_MGCausale = DO.Cd_MGCausale " + ;

								"WHERE (PCCarQs != 0 Or PCScaQs != 0 Or ACCarQs != 0 Or ACScaQs != 0) And DO.Cd_DO = " + Format4SPT(DoTes.Cd_Do))

	EndIf

	

	If lDoUIMgMovEdit And oCausaleInfo.MovimentaComponenti  && And !Empty(xGetEnv('Fedi_MgMovDoc')) 

		oMgMovDocForm = RunFedi('Fedi_MgMovDoc', ThisForm, 'DoTes.Id_DoTes = ' + Transform(DoTes.Id_DoTes))

		If Vartype(oMgMovDocForm ) == 'O'

			oMgMovDocForm.Show(1)

		EndIf

	EndIf



	** Archiviazione automatica - 31/08/2020: la stampa del PDF Immagine del Documento la devo fare prima del cmdPrint() per non fare andare in conflitto i nomi dei file

	**														nel caso ci fosse un secondo modulo che va in accodamento al modulo "Ufficiale". In questo modo viene creato il pdf da allegare

	**														al DMS, poi viene cancellato ed infine vengono stampanti i moduli richiesti dalla pagina "Moduli".

	If DoTes.AutoArchivia And DoTes.ModificabilePdf

		oApp.Dms.Attach_DoTes_PDF(DoTes.Id_DoTes, .T.)

	EndIf 



	**

	ThisForm.cmdPrint()



	With ThisForm.DE.DoRigPackList

		TableRevert(.T., 'DoRigPackList')

		.Buffering = 3

		.RunCmd('ZAP')

		.Buffering = 5

	EndWith



	** Gestione Processi

	If lInsertMode	And oApp.LicInfo.ArcaGP And oApp.oUser.AccessGP And !PemStatus(This, 'oHelperGP', 5)

		Local nId_GPIstanzaAttivita

		nId_GPIstanzaAttivita = GPAttivita_Attach_FromNewDoTes(DoTes.Id_DOTes, ThisForm)

		If !IsEmpty(nId_GPIstanzaAttivita)		

			GPIstanzaAttivita_EditAfterCreate(nId_GPIstanzaAttivita)

		EndIf 

	EndIf 

	

	**

	RecSignClear(ThisForm.PF.pgGenerale.PF.pgRighe.Cnt.Grid)

	RecSignClear(ThisForm.PF.pgGenerale.PF.pgPiede.Cnt.cntFattura.Grid)

EndIf



** Integrazione autotd

Iif(lRet And ThisForm.PF.pgGenerale.txtCd_DO.Field.FKRecord.FTE_AutoTD, Thisform.CmdFTEAutoTD(, 0), .T.)



If !IsEmpty(ThisForm.ModeFromPrelievo) Or Thisform.ModeFromArcaGP

	** Se invocata da prelievo automatico allora chiudo anche la form (HideOnClose è impostato a .T.)

	If lRet

		This.cmdExit()

	EndIf

EndIf



If lInsertMode And lRet

	nOldWA = Select(0)

	Select Dotes

	Scatter Name This.oRecPrev Memo 

	Select (nOldWA)

EndIf



If lInsertMode And lRet And DoTes.PeppolDespatch = 1

	** Ho appena salvato un nuovo DDT, chiedo di inviarlo alla rete PEPPOL

	If xMessageBox('Invio il DDT alla rete PEPPOL?',4+32) = 6

		This.PF.pgGenerale.PF.pgGenerale.cntPeppol.btnUpload.Click() 

	EndIf 

EndIf



Return lRet

ENDPROC

PROCEDURE annulla

LParameters lInsertMode



This.DE.DoDB.Zap(.T.)

This.DE.DoDBAttivita.Zap(.T.)

This.DE.DoDBMateriale.Zap(.T.)

*This.DE.DoRigPackList.Zap(.T.)



DoDefault(lInsertMode)



Thisform.oDoIntento.Wrk_Destroy()



If !IsEmpty(This.ModeFromPrelievo) Or This.ModeFromArcaGP

	** Se invocata da prelievo automatico allora chiudo anche la form (HideOnClose è impostato a .T.)

	This.cmdExit()

EndIf

ENDPROC

PROCEDURE querydelete

Local cMsg, oRec, cStmt, lCanDelete, lRefreshNeeded



lCanDelete = DoDefault(@lRefreshNeeded, 'il documento')

If lRefreshNeeded

	** Disponibile se necessario (vedi Fedi_CGMovT)

EndIf



If lCanDelete



	** Controllo stato modificabile

	If lCanDelete

		If !DoTes.Modificabile And !QuestionBox(RL_INFINITE, "Il documento non è cancellabile.", "modificare il documento")

			lCanDelete = .F.

		EndIf

	EndIf



	** Controllo stato evasione

	If lCanDelete		

		Text To cStmt TextMerge NoShow



			Select Top 1

				te.Cd_Do,

				te.DataDoc,

				te.NumeroDoc

			From 	 DoRig r

			Inner Loop Join DoRig re On re.Id_DoRig_Evade = r.Id_DoRig

			Inner Join DoTes te On te.Id_DoTes      = re.Id_DoTes

			Where r.Id_DoTes = << Format4Spt(DoTes.Id_DoTes) >>



		EndText

		oRec = xSqlExec2Obj(cStmt)	

		If Vartype(oRec) == 'O'

			cMsg = "Il documento che si sta eliminando" + CRLF + "è già stato evaso dal documento " + CRLF + CRLF + ;

				   "   " + RTrim(oRec.Cd_Do) + ' ' + AllTrim(oRec.NumeroDoc) + ' del ' + DToC(oRec.DataDoc)

			If !QuestionBox(RL_POWER_USER, cMsg, "eliminare il documento")

				lCanDelete = .F.

			EndIf

		EndIf

	EndIf



	** Controllo stato contabilizzazione sono se attiva contabilità o senza coge con export attivo

	If lCanDelete And (oApp.LicInfo.CG_Main Or !CG_Export())

		Text To cStmt TextMerge NoShow

			

			Select Count(*) As Counter

			From CGMovT

			Where Id_DoTes = << Format4Spt(DoTes.Id_DoTes) >> And ProvvisorioDaDocumento = 0		



		EndText

		oRec = xSqlExec2Obj(cStmt)	

		If oRec.Counter > 0 And !QuestionBox(RL_POWER_USER, 'Il movimento contabile associato al documento è già stato contabilizzato.', 'eliminare il documento')

			lCanDelete = .F.

		EndIf

	EndIf

	

	** Controllo piani di elaborazione

	If lCanDelete

		Text To cStmt TextMerge NoShow

			

			Select Convert(Bit, Case When Exists(

				Select * From MPData Where Id_DoRig In (Select Id_DoRig From DoRig Where Id_DoTes = << FormatI4Spt(DoTes.Id_DoTes) >>)

			) Then 1 Else 0 End)



		EndText

		If xSqlExec2Var(cStmt) And !QuestionBox(RL_POWER_USER, 'Almeno una riga del documento è collegata ad un Piano di Elaborazione.', 'eliminare il documento')

			lCanDelete = .F.

		EndIf

	EndIf

		

	** Fattura Elettronica	

	If !IsEmpty(DOTes.FTE_Status)



		Local oFTEW 

		oFTEW = xSqlExec2Obj('Select InviatoHUB, InviatoSDI, Emesso From FTE_WorkFlow Where FTE_Status = ' + FormatC4Spt(DOTes.FTE_Status))



			Do Case

				Case oFTEW.InviatoHUB = 1 Or oFTEW.InviatoSDI = 1

					** Documento INVIATO				

					If xMessageBox('Il documento elettronico risulta in elaborazione.' + CRLF + 'Il file XML non può essere cancellato.' + CRLF + CRLF + ;

								 	   'Confermi la cancellazione del documento?', 4+32) = 7

						Return .F.

					EndIf 				



				Case oFTEW.Emesso = 1

					** Documento EMESSO (cioè inviato a SDI senza errori)

					If xMessageBox(Iif(DoTes.CliFor = 'C', 'Il documento elettronico risulta TRASMESSO.' + CRLF + 'Il file XML non può essere cancellato.' + CRLF, ;

																		Iif(InList(DoTes.TipoDocumento, 'F', 'A'), 'La Fattura', 'La Nota di Accredito') + ' è stata creata da un documento elettronico.') + CRLF + ;					

								 	   'Confermi la cancellazione del documento?', 4+32) = 7

						Return .F.

					EndIf				



			EndCase

	

	EndIf 

	

EndIf

Return lCanDelete



ENDPROC

PROCEDURE Init

This.PF.pgGenerale.txtCd_Do.Field.DoBitMask = This.DoBitMask

This.Caption = This.Caption + ' ' + ProcessDocMode_GetCaption(This.DoBitMask)



** Verifico che siano agganciati i file necessari

SetProcedure('Forms\Fedi_Doc.fxp')

SetProcedure('Forms\Fte_Reader.fxp')



** Controllo dei Contatori per le fatture elettroniche

If Bitand(This.DoBitMask, TD_CA_FATTURA) != 0 Or Bitand(This.DoBitMask, TD_CA_FATTURA_ACC) != 0 Or Bitand(This.DoBitMask, TD_CA_NOTA_ACCREDITO) != 0

	If !Check_CN_FTE(Thisform)

		Return .F.

	EndIf 

EndIf 



If !DoDefault()

	Return .F.

EndIf



**

MNewObject0(This, 'oDoIntento', 'DOIntento_Engine', 'Forms\Fedi_Doccommon.fxp')

This.AddProperty('DoIntento', .F.)



** Support Object 4 AUTOTD ENGINE

MNewObject(This, 'oAutoTD', 'FTE_Autotd_Engine', 'Forms\Fte_Autotd.fxp')



** ----- LICADAPTER



** N.b.: codice di controllo simile in amk_ied_importer



If	IsEmpty(Impostazione.Cd_CGConto_Acq ) Or ;

	IsEmpty(Impostazione.Cd_CGConto_Ven ) Or ;

	IsEmpty(Impostazione.Cd_Aliquota_Acq) Or ;

	IsEmpty(Impostazione.Cd_Aliquota_Ven)

	xMessageBox(Thisform.TB_(,"88E4B078-E206-4818-87BD-4AFE48E0958C", 'Attenzione: non sono stati definiti nelle impostazioni i default per la gestione dei documenti.'), 48)

EndIf



If Bitand(This.DoBitMask, TD_CA_FATTURA + TD_CA_FATTURA_ACC + TD_CA_NOTA_ACCREDITO) != 0 And ;

	!xSqlExec2Var("Select Convert(Bit, Count(*)) As SpeseBolliEsenteOk From Impostazione Where Cd_Impostazione = 'SPESE_BOLLI_ESENTE' And Cd_CGConto_2  Is Not Null And Cd_Aliquota_2 Is Not Null") 

	xMessageBox(Thisform.TB_(,"B43933B3-E370-4B90-B013-463670A7E2A2", 'Attenzione: non sono stati definiti nelle impostazioni i default per i bolli su esente.'), 48)

EndIf



This.AddProperty('SkipModuliRequery',  .F.)

This.AddProperty('Cd_MGCausale',   		 '')

This.AddProperty('Cd_MG_A',  		 		 '')

This.AddProperty('Cd_MG_P', 	 	 		 '')

This.AddProperty('Id_DoTesNewDup', 		  0)

This.AddProperty('MagAFlag',				.F.)

This.AddProperty('MagPFlag',				.F.)

This.AddProperty('MagAFix',				.F.)

This.AddProperty('MagPFix',  				.F.)

This.AddProperty('IsPrelevabile', 		.F.)



** Contiene l'ultimo record di testa salvato nel Save() per riproporli al prossimo inserimento

This.AddProperty('oRecPrev', 	NULL)



** Particolarizzazione form

This.DoUiHonor()



** Evidenziazione della riga

This.AddProperty('ShowId_DoRig',      Iif(Vartype(This.Parameters.ParentForm) == 'O' And PemStatus(This.Parameters, 'Param2', 5), This.Parameters.Param2, -10000000))		&& In teoria  è difficile inserire un documento con 10.000.000 di righe...

This.AddProperty('ShowId_DoRigSpesa', Iif(Vartype(This.Parameters.ParentForm) == 'O' And PemStatus(This.Parameters, 'Param3', 5), This.Parameters.Param3, -10000000))



** ----- LICADAPTER

Local cPopupName

cPopupName = This.Mnu_GetPopupName(MB_VIEW_PAD)



If !oApp.LicInfo.Allegati

	ThisForm.PF.pgAllegati.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

EndIf



If !oApp.LicInfo.Commesse

	Thisform.PF.pgGenerale.PF.pgGenerale.cntVarie.txtCd_Commessa.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

EndIf



** Dalla 2/2015 SP1 il cntConservazioneInvio è sempre visibile se si ha il modulo DO_MAIN



** Dopo il PF.REFRESH() ho il valore dei field sincronizzati con il controlsource

BindEvent(This.PF, 'Refresh', This, 'SetRegimeIva', 1)



** AUTOTD -> Start settings

Thisform.AutoTD_Init()



Return .T.



ENDPROC

PROCEDURE inittoolbar

DoDefault()



Local i, oBtn



With Thisform.Toolbar

	**	.Buttons('NEW').BUTTONMENUS('NEWDUP').ENABLED = .F.

	.Buttons('ROWADD').Visible 		= .T.

	.Buttons('ROWDEL').Visible 		= .T.

	.Buttons('ROWINS').Visible 		= .T.

	.Buttons('ROWDOWN').Visible 		= .T.

	.Buttons('ROWUP').Visible 			= .T.

	.Buttons('ROWCOPY').Visible 		= .T.

	.Buttons('ROWPASTE').Visible 		= .T.



	i = .Buttons('SEP_AFTER_PREVIEW').Index + 1



	oBtn = .Buttons.Add(i, 'STOP_PA_EDIT', , 0, 'RUOTE04')

	oBtn.ToolTipText = TT_(, "F03534F5-E12B-42B6-867D-0DB63B8A24AC", "Opzioni fatturazione automatica")

	oBtn.Visible = .F.

	i = i + 1



	oBtn = .Buttons.Add(i, 'VIEWSCADENZA', , 0, 'CALENDAR')

	oBtn.ToolTipText = TT_(, "205B384B-FE57-4C49-A17C-530037EAFC44", 'Visualizza Scadenze collegate')

	i = i + 1



	If oApp.LicInfo.CG_Main



		oBtn = .Buttons.Add(i, 'VIEWCG', , 0, 'NOTE14')

		oBtn.ToolTipText = TT_(, "7EC8B732-E79F-441F-AA98-F1B453F0DA0D", 'Visualizza registrazione contabile collegata')

		i = i + 1



		oBtn = .Buttons.Add(i, 'VIEWINTRA', , 0, 'GLOBE')

		oBtn.ToolTipText = TT_(, "718CC496-F67F-41BA-AF39-8FC0F07FC860", 'Visualizza righe Intra collegate')

		i = i + 1

	EndIf



	.Buttons.Add(i,'SEP_BEFORE_XML',,3)

	i = i + 1



	oBtn = .Buttons.Add(i, 'FTEVIEW', , 0, 'FTE')

	oBtn.ToolTipText = TT_(, "95A3ED1A-DC8C-4B1F-8967-38BAED30E556", "Visualizza Fattura Elettronica")

	oBtn.Visible = .T.

	i = i + 1



	If Bitand(This.DOBitMask, TD_CP_FATTURA + TD_CP_FATTURA_ACC + TD_CP_NOTA_ACCREDITO ) != 0

		oBtn = .Buttons.Add(i, 'FTELINK', , 0, 'FTE_LINK')

		oBtn.ToolTipText = TT_(, "73D46095-EB0E-4DE3-95E0-3BCE953242A9", "Collega file XML Fattura Elettronica.")

		oBtn.Visible = .T.

		i = i + 1

	EndIf 



	If Bitand(This.DOBitMask, TD_CA_FATTURA + TD_CA_FATTURA_ACC + TD_CA_NOTA_ACCREDITO ) != 0

		oBtn = .Buttons.Add(i, 'FTESEND', , 0, 'FTE_SEND')

		oBtn.ToolTipText = TT_(, "F50A4EE5-4447-4274-9796-DD180E1280EC", "Invia Fattura Elettronica")

		oBtn.Visible = .T.

		i = i + 1

	EndIf 



	If Bitand(This.DOBitMask, TD_CA_FATTURA + TD_CA_FATTURA_ACC + TD_CA_NOTA_ACCREDITO ) != 0

		oBtn = .Buttons.Add(i, 'FTE_HUBINSPECTOR', , 0, 'FTE_HUBINSPECTOR')

		oBtn.ToolTipText = TT_(, "F50A4EE5-4447-4274-9796-DD180E1280EC", "HUB Inspector")

		oBtn.Visible = .T.

		i = i + 1

	EndIf 	



	oBtn = .Buttons.Add(i, 'FTEXML',	, 0, 'DETAILS')

	oBtn.ToolTipText 	= TT_(, "315C0B9E-3D09-4D2B-A952-FD22B4D0DDBC", 'Dati aggiuntivi Fattura Elettronica')

	oBtn.Visible 		= oApp.LicInfo.FatturaElettronica Or oApp.LicInfo.FatturaElettronicaPassiva

	i = i + 1



	This.AutoTD_Bar('TB')



	.Buttons.Add(i,'SEP_AFTER_XML',,3)

	i = i + 1

	

	oBtn = .Buttons.Add(i, 'DOPUSH',	, 0, 'DOCUMENTPUSH')

	oBtn.ToolTipText = TT_(, "DDE8E9A7-6FC6-4CFA-AC96-B4CB33BAD63F", 'Evadi documento')

	i = i + 1



	.Buttons.Add(i,'SEP_AFTER_DOPUSH',,3)

	i = i + 1



Endwith

ENDPROC

PROCEDURE querysave

LParameters lInsertMode



If !DoDefault(lInsertMode)

	Return .F.

Else

	Thisform.Title_Bar.SetFocus()	&&--> BUG 1714 e 1496

EndIf



Local lRet, cMessage

Local oDoRec, oCF, oDoTotali, oElem, oWA 

Local nSpeseBolli

Local xCheckLotti, xCheckMatr, xCheckUbic



lRet = .T.

oWA  = SelectWA('DoRig')			&& Seleziona come corrente la WA DoRig; memorizza record corrente di DoRig e WA corrente attuale e nel destroy risistema record corrente in DoRig e WA corrente



**	Cd_Do not emtpy

If IsEmpty(DoTes.Cd_Do)

	xMessageBox(Thisform.TB_(,'7877C2ED-2F5E-43FB-A12D-CFD14D820C29', 'Tipo Documento obbligatorio.'), MB_OK + MB_ICONSTOP)

	This.PF.pgGenerale.txtCd_Do.SetFocus()

	Return .F.

EndIf



**	Cd_CF not emtpy

If IsEmpty(SubStr(DoTes.Cd_CF, 2))

	xMessageBox(Thisform.TB_(,'0F372CDB-8A37-4817-AF29-0E64E9C06368', 'Codice Cliente / Fornitore obbligatorio.'), MB_OK + MB_ICONSTOP)

	This.PF.pgGenerale.txtCd_CF.SetFocus()

	Return .F.

EndIf



** Verifico la presenza di altri documenti con lo stesso numero. Spostato il controllo dal TRG per avere più flex anche in import di COGE.

cText = Thisform.CheckNumDocRif()

If !Empty(cText) And xMessageBox(cText + Chr(13) + Chr(13) + 'Proseguo ?', MB_ICONEXCLAMATION + MB_YESNO + MB_DEFBUTTON2) = IDNO

        Return .F.

EndIf



** Controllo che siano stati inseriti gli agenti sulla testa se sono presenti percentuali di provvigione sulle righe



If IsEmpty(DoTes.Cd_Agente_1) Or IsEmpty(DoTes.Cd_Agente_2)

	cMessage = ''

	If IsEmpty(DoTes.Cd_Agente_1)

		Locate For !IsEmpty(ProvvigioneRiga_1)

		cMessage = Iif(Found(), 'Agente 1' + CRLF, '')

	EndIf

	If IsEmpty(DoTes.Cd_Agente_2)

		Locate For !IsEmpty(ProvvigioneRiga_2)

		cMessage = cMessage + Iif(Found(), 'Agente 2' + CRLF, '')

	EndIf

	If !IsEmpty(cMessage)

		If	xMessageBox(Thisform.TB_(,'166C5D7A-C000-4710-AAAD-D27FAD7B2BAE', 'Ci sono righe di provvigione ma non sono definiti i campi ad esse associati:' + CRLF + '%1!' + CRLF + 'Continuare lo stesso ?', cMessage), MB_YESNO + MB_ICONQUESTION) = IDNO

			This.PF.pgGenerale.PF.ActivePage = 1

			This.PF.pgGenerale.PF.pgGenerale.cntPagamento.txtCd_Agente.Field.SetFocus()

			Return .F.

		EndIf

	EndIf

EndIf



** Controllo contabilità analitica: No CDA e Formula insieme

Locate For !IsEmpty(DoRig.Cd_CACda) And !IsEmpty(DoRig.Cd_CAFormula)

If Found()

	xMessageBox(Thisform.TB_(,'FD3C9C9D-9A2B-46D6-9119-6043B30013E3', 'Non è consentito indicare sia il centro di analisi che la formula per la ripartizione nelle righe del documento.'))

	Return .F.

EndIf

Select DoRigSpesa

Locate For !IsEmpty(DoRigSpesa.Cd_CACda) And !IsEmpty(DoRigSpesa.Cd_CAFormula)

If Found()

	xMessageBox(Thisform.TB_(,'E0154F95-2B75-44D7-B6EC-D76F620F9F00', 'Non è consentito indicare sia il centro di analisi che la formula per la ripartizione nelle righe di spesa.'))

	Return .F.

EndIf

Select DoRig



** Controllo le righe che hanno almeno il codice o la descrizione (le altre vengono eliminate nel DE.DoRig.Update_Records)

Locate For !Empty(Cd_AR) Or !Empty(Descrizione)

If !Found()

	xMessageBox(Thisform.TB_(,'19911588-5DED-4203-B9AB-B09844AC59E7', 'Nessuna riga merce inserita.'), MB_OK + MB_ICONSTOP)

	Return .F.

EndIf



** Controllo Obbligatorietà dei magazzini, per le righe con codice articolo



If !IsEmpty(DOTes.Cd_MGCausale)

	Local oMagFlag

	oMagFlag = xSqlExec2Obj('Select MagPFlag, MagAFlag From MGCausale Where Cd_MGCausale = ' + FormatC4Spt(DOTes.Cd_MGCausale))



	If VarType(oMagFlag) = 'O'



		Local cTable, cResult



		If oMagFlag.MagPFlag 

			Select Cd_AR From DoRig With (Buffering = .T.) Where !IsEmpty(DoRig.Cd_AR) And IsEmpty(DoRig.Cd_MG_P) Into Cursor _ar_2check_mg

			cResult = ''

			If Reccount() > 0

				cTable = ''

				CursorToServer('_ar_2check_mg', @cTable)

				cResult = xSqlExec2Var("Select dbo.CsCat(' ' + AR.Cd_AR) From AR Join " + cTable + " X On AR.Cd_AR = X.Cd_AR Where AR.Fittizio = 0")				

			EndIf 

			Use In _ar_2check_mg



			If !IsEmpty(cResult)

				xMessageBox(TB_(, "0179A54D-FFA5-440A-80AB-DC89F5DE2068", "È necessario inserire il magazzino di partenza!" + CRLF + "Articoli:" + Rtrim(cResult)), MB_OK + MB_ICONSTOP)

				Return .F.

			EndIf 						

		EndIf 

		

		If oMagFlag.MagAFlag 

			Select Cd_AR From DoRig With (Buffering = .T.) Where !IsEmpty(DoRig.Cd_AR) And IsEmpty(DoRig.Cd_MG_A) Into Cursor _ar_2check_mg

			cResult = ''

			If Reccount() > 0

				cTable = ''

				CursorToServer('_ar_2check_mg', @cTable)

				cResult = xSqlExec2Var("Select dbo.CsCat(' ' + AR.Cd_AR) From AR Join " + cTable + " X On AR.Cd_AR = X.Cd_AR Where AR.Fittizio = 0")				

			EndIf 

			Use In _ar_2check_mg



			If !IsEmpty(cResult)

				xMessageBox(TB_(, "DA96415D-B5C2-4644-8CFD-7A4CE1D9DCF1", "È necessario inserire il magazzino di arrivo!" + CRLF + "Articoli:" + Rtrim(cResult)), MB_OK + MB_ICONSTOP)

				Return .F.

			EndIf 

		EndIf

	EndIf 

EndIf  



** Controllo Iban

If !This.PF.pgGenerale.PF.pgGenerale.cntDatiContabili.TxtIban.Field.CodeCheck()

	Return .F.

EndIf

	

** Controllo che siano presente le impostazioni per le spese bolli su esente se c'è il check in interfaccia

Local oChkSpeseBolli

oChkSpeseBolli = This.PF.PGGenerale.PF.PgPiede.Cnt.cntFattura.chkSpeseBolli



If oChkSpeseBolli.Visible And oChkSpeseBolli.Value And ;

   !xSqlExec2Var("Select Convert(Bit, Count(*)) As SpeseBolliEsenteOk From Impostazione Where Cd_Impostazione = 'SPESE_BOLLI_ESENTE' And Cd_CGConto_2  Is Not Null And Cd_Aliquota_2 Is Not Null") 

	xMessageBox(Thisform.TB_(,'74FCAA68-3F9E-4C46-8157-37C360835A88', 'Attenzione: non sono stati definiti nelle impostazioni i default per i bolli su esente.' + CRLF + CRLF + 'Non è possibile proseguire con la registrazione!'), 16)

	Return .F.

EndIf



** ---------------------------------------------

** Controllo obbligatorietà LOTTI



xCheckLotti = Check_DORig_Lotto('DORig', DoTes.Cd_DO)

If Vartype(xCheckLotti) = 'O' And xCheckLotti.Count > 0



	cMessage = ''

	For Each oElem In xCheckLotti

		cMessage = cMessage + CRLF + Tran(oElem.Riga, '####') + "  " + Padr(oElem.Cd_AR, 20) + "  " + Padr(oElem.Cd_ARMisura, 2) + " " + Transform(oElem.Qta, '##,###,###.##')

	Next 

	

	xMessageBox(TB_(, "61B1A158-EA88-4D62-A1C5-076F1BE670D2", "Il controllo dell'obbligatorietà del lotto è fallito per le seguenti righe:" + CRLF + CRLF + "Riga  Articolo" + "%1!", cMessage), 16)

	Return .F.

EndIf 



** ---------------------------------------------

** Controllo obbligatorietà MATRICOLE



xCheckMatr = Check_DORig_Matricole('DORig', DoTes.Cd_DO)

If Vartype(xCheckMatr) = 'O' And xCheckMatr.Count > 0



	cMessage = ''

	For Each oElem In xCheckMatr

		cMessage = cMessage + CRLF + Tran(oElem.Riga, '####') + "  " + Padr(oElem.Cd_AR, 20) + "  " + Padr(oElem.Cd_ARMisura, 2) + " " + Transform(oElem.Qta, '##,###,###.##')

	Next 

	

	xMessageBox(TB_(, "84C0E55D-9203-476A-AE06-EC19D64F11B9", "Il controllo dell'obbligatorietà delle matricole è fallito per le seguenti righe:" + CRLF + CRLF + "Riga  Articolo" + "%1!", cMessage), 16)

	Return .F.

EndIf



** ---------------------------------------------

** Controllo obbligatorietà UBICAZIONI



xCheckUbic = Check_DORig_Ubicazione('DORig', DoTes.Cd_DO)

If Vartype(xCheckUbic) = 'O' And xCheckUbic.Count > 0



	cMessage = ''

	For Each oElem In xCheckUbic

		cMessage = cMessage + CRLF + Tran(oElem.Riga, '####') + "  " + Padr(oElem.Cd_AR, 20) + "  " + Padr(oElem.Cd_ARMisura, 2) + " " + Transform(oElem.Qta, '##,###,###.##')

	Next 

	

	xMessageBox(TB_(, "54FCA66B-589D-4319-98A9-2BB9E515BB7B", "Il controllo dell'obbligatorietà delle ubicazioni è fallito per le seguenti righe:" + CRLF + CRLF + "Riga  Articolo" + "%1!", cMessage), 16)

	Return .F.

EndIf



If !This.CheckFifoContinuo()

	Return .F.

Endif



** ---------------------------------------------

** Questo flag impedisce di ricaricarsi i valori di default della griglia dei moduli nel caso in cui siano stati modificati

**	???????????????????????

This.SkipModuliRequery = .T.



oDoRec = This.PF.pgGenerale.txtCd_Do.Field.FKRecord	

** fatturazione

oCF    = ThisForm.PF.pgGenerale.PF.pgGenerale.txtCF_Fatt.Field.FKRecord

** intestatario (eventualmente)

oCF	 = Iif(!IsEmpty(oCF.Cd_CF), oCF, ThisForm.PF.pgGenerale.txtCd_CF.Field.FKRecord)



** Ricalcolo i totali in alcuni casi e lo faccio una sola volta per tutti i casi necessari (in EDIT si potrebbe farlo sempre)

** Verifica fido; Verifica spese bolli se gestione manuale

If (oDoRec.UIchkFido And oDoRec.UIchkFidoFin And oCF.Fido != 0) Or !oChkSpeseBolli.Value

	oDoTotali = This.TotaleDocumento()

EndIf



** VERIFICA PRESENZA/ASSENZA SPESE BOLLI IN EDIT

** Verifico se sono presenti spese bolli per esenzione non richieste o mancanti in caso l'utente voglia gestire manualmente.

If (oChkSpeseBolli.Visible and !oChkSpeseBolli.Value) And Impostazione.Imp_DOEsente_Limite > 0 And Impostazione.Imp_DOEsente_Spese > 0 And Vartype(oDoTotali) == 'O' And ;

	InList(oDoRec.TipoDocumento, 'F', 'A', 'N')



	Calculate Cnt() For TipoRigaSpesa == 'Z' To nSpeseBolli In DoRigSpesa



	** Le spese NON SONO presenti ma sussitono le condizioni per applicarle

	** l'importo delle esenzioni soggette supera la soglia ed è richiesta l'applicazione da CF

	If	nSpeseBolli = 0 And oDOTotali.TotEsenteBolloE >= Impostazione.Imp_DOEsente_Limite And ;

		xMessageBox(Thisform.TB_(,'7E5B3278-5E6E-49AA-8ADD-BB3B6C2DF70E', ;

			"Sono stati individuati i presupposti per l'applicazione delle spese di bolli per esenzione ma non sono state rilevate le spese nel documento. " + CRLF + ;

			"Si consiglia di verificarne la presenza nell'apposito elenco." + CRLF + ;

			"Continuare lo stesso ?"), MB_YESNO + MB_ICONQUESTION) = IDNO

		Thisform.PF.pgGenerale.PF.ActivePage = 3

		Return .F.

	EndIf

	

	** Le spese SONO presenti ma non sussitono le condizioni per applicarle

	If	nSpeseBolli != 0 And oDOTotali.TotEsenteBolloE < Impostazione.Imp_DOEsente_Limite And !oChkSpeseBolli.Value And ;

		xMessageBox(Thisform.TB_(,'4864C4F9-6A8D-479F-BFF0-48A50A830F8F', ;

			"Non sono stati individuati i presupposti per l'applicazione delle spese di bolli per esenzione ma sono state rilevate le spese nel documento." + CRLF + ;

			"Si consiglia di verificarne la presenza nell'apposito elenco." + CRLF + ;

			"Continuare lo stesso ?"), MB_YESNO + MB_ICONQUESTION) = IDNO

		Thisform.PF.pgGenerale.PF.ActivePage = 3

		Return .F.

	EndIf



EndIf



** Controllo Fido

If !This.ControlloFido(oDoTotali)

	Return .F.

EndIf



** Controllo protocolli proposti

If !This.CheckNextNumDoc()

	Return .F.

EndIf



** Verifico che SE le matricole ci sono e le impostazioni del BLS lo richiedono

** allora QtaUM1 e #Matricole siano coerenti; inoltre verifico che le matricole

** SE ci sono siano univoche;  l'obbligatorietà delle matricole  per l'articolo

** viene invece testata nel trigger di MGMov in modo sicuro



** Tale controllo è fatto anche dal CheckMatricole della Detail



** ----- LICADAPTER

If oApp.LicInfo.DO_LottiMatr

	Select DoRig

	Scan

		If !This.oMatricole.CheckMatricoleXml(.F.)

			Return .F.

		EndIf

	EndScan

EndIf



** ----- LICADAPTER

If oApp.LicInfo.CG_Main



	** Check date competenza compilate (in unione Grid_Isvalid)

	Select DoRig

	Locate For ;

		(!IsEmpty(DoRig.RR_DataInizio) Or !IsEmpty(DoRig.RR_DataFine)) And ;

		( IsEmpty(DoRig.RR_DataInizio) Or  IsEmpty(DoRig.RR_DataFine))

	

	If Found('Dorig')

		xMessageBox(Thisform.TB_(,'4EF1DF83-3B7E-4BAE-A28A-F1CC1D0D99A6', 'Data di inizio o fine del periodo di competenza non compilata.'))

		Return .F.

	EndIf

	

	** Data inizio <= Data fine

	Locate For (!IsEmpty(DoRig.RR_DataInizio) And !IsEmpty(DoRig.RR_DataFine)) And (DoRig.RR_DataInizio > DoRig.RR_DataFine)

	If Found('Dorig')

		xMessageBox(Thisform.TB_(,'BE3EA43B-DAD8-4317-9BC6-9049B41D9CA0', 'La data di inizio del periodo di competenza non può essere posteriore a quella di fine.'))

		Return .F.

	EndIf

			

	** Check x RR

	If !This.RR_Validate('DORig')

		Return .F.

	EndIf



	** Check Test Cassa previdenza x Ritenute

	If !This.RA_Previdenza_Check(1)

		Return .F.

	EndIf



EndIf



**	 ** ------------------------------------------------------------------------------------------------

**	 ** Controllo coerenza delle righe "PADRE" e "COMPONENTE"

**	 **  - ogni riga "C" deve essere precedura da una riga "C" oppure "P"

**	 **  - ogni riga "P" deve essere seguita   da una riga "C"  



**	Local i, aRighe[1]

**	Local cMsg



**	cMsg = ''

**	i 	  = 0



**	Select DoRig

**	Set Order To Riga

**	Scan For InList(TipoPC, 'P', 'C')

**		i = i + 1

**		Dimension aRighe(i)

**		aRighe[i] = DORig.Riga			&& salvo in un array tutti i valori del campo RIGA delle righe P o C.

**	EndScan 



**	For i = 1 To Alen(aRighe)			&& processo tutte le righe in ordine di RIGA, controllando la riga precedente o successiva in base al TipoPC

**		Locate For Riga = aRighe[i]

**		Do Case 

**			Case DoRig.TipoPC = 'P'

**				Skip +1

**				If Eof() Or DoRig.TipoPC != 'C'

**					cMsg = cMsg + 'La riga ' + Transform(aRighe[i]) + ' di tipo "Padre" non è seguita da altra riga "Componente".' + CRLF

**				EndIf 

**				

**			Case DoRig.TipoPC = 'C'

**				Skip -1

**				If Bof() Or !InList(DoRig.TipoPC, 'P', 'C')

**					cMsg = cMsg + 'La riga ' + Transform(aRighe[i]) + ' di tipo "Componente" non è preceduta da altra riga "Componente" o "Padre".' + CRLF

**				EndIf 

**		EndCase  	

**	Next 



**	If !IsEmpty(cMsg)

**		xMessageBox('Attenzione!' + CRLF + cMsg 																 , 48)

**	**	xMessageBox('Attenzione!' + CRLF + cMsg + CRLF + 'Non è possibile salvare il documento.', 16)

**	**	Return .F.

**	EndIf  



** ------------------------------------------------------------------------------------------------

** Controllo presenza Scadenze con Provvigioni liquidate, solo se sono in modifica...



If lInsertMode = .F.



	Text To cStmt TextMerge NoShow

		If Exists(	Select * From DoTes

											Join SC On Sc.Id_DOTes = DOTes.Id_DoTes 

											Join Provvigione P On P.Id_SC = Sc.Id_SC 

						Where 

							DOTes.Id_DoTes = <<FormatI4Spt(DoTes.Id_DoTes)>> And P.DataLiquidazione Is Not Null)

			Select 1

		Else

			Select 0

	EndText



	If xSqlExec2Var(cStmt) = 1 And ;

		xMessageBox(Thisform.TB_(,'BA7B2F2B-9CDB-4298-A5D5-FCBBEA90353D', ;

					"Per questo documento esistono delle scadenze con provvigioni già liquidate." + CRLF + ;

					"Potrebbero venir rigenerate tali scadenze e relative provvigioni." + CRLF + ;

					"Continuare lo stesso ?"), MB_YESNO + MB_ICONEXCLAMATION) = IDNO



		Return .F.

	EndIf  

EndIf 



** ------------------------------------------------------------------------------------------------



** Verifico compatibilità check iva differita della testa con le righe presenti

If !This.CheckIvaDifferita()

	Return .F.

EndIf



** Verifico compatibilità codici iva moss

If !This.IvaMoss_Chk()

	Return .F.

EndIf



** Verifico congruenza per applicazione IVA SPLIT - CICLO ATTIVO

If !This.CheckIvaSplit()

	Return .F.

EndIf



** Verifico congruenza per applicazione IVA SPLIT - CICLO PASSIVO

If !This.SP_Check()

	Return .F.

EndIf



** Verifico congruenza RC

If !This.RC_Check()

	Return .F.

EndIf



** Verifico Applicazione Dichiarazione intento

If !This.DOINTENTO_Check()

	Return .F.

EndIf



** ------------------------------------------------

** Verifico presenza di articoli con stato bloccato

clist = ''

Scan For !IsEmpty(Dorig.Cd_AR)

	Text To cStmt Textmerge

			If Exists(	Select ARStato.*

							From 	 AR 

								Left Join ARStato On ARStato.Cd_ARStato = AR.Cd_ARStato

							Where

								AR.Cd_AR = <<FormatC4Spt(Dorig.Cd_AR)>> And (ARStato.<<Iif(DoTes.CliFor = 'C', 'Clienti', 'Fornitori')>> = 'B' Or AR.Obsoleto = 1)

						 ) 

						 Select 1 Else Select 0

	EndText

	

	If xSqlExec2Var(cStmt) = 1

		cList = cList + ', ' + TRIM(Dorig.Cd_AR)

	Endif

Endscan



If !IsEmpty(cList)

	If xMessageBox(TB_(,'963D841C-F528-4674-94B7-A31672658B73', 'I seguenti articoli risultano bloccati/obsoleti: %1!. Vuoi proseguire lo stesso?', + Substr(cList, 2)), 4+32) = 7

		Return .F.

	Endif

Endif



** ------------------------------------------------

** Fattura Elettronica Attiva

Local oDO, oCF, oDataDoc



oDO 		= This.PF.pgGenerale.txtCd_DO.Field.FKRecord

oCF 		= This.PF.pgGenerale.txtCd_CF.Field.FKRecord

oDataDoc = This.PF.pgGenerale.txtDataDoc.Field



If oApp.LicInfo.FatturaElettronica And InList(oDO.TipoDocumento, 'F', 'A', 'N') And Left(oCF.Cd_CF, 1) = 'C'

	If xSqlExec2Var('Select FatturaElettronica From CN Join DO On CN.Cd_CN = DO.Cd_CN Where DO.Cd_DO = ' + FormatC4Spt(DoTes.Cd_DO)) = .F.

		** Contatori NON elettronici

		Do Case

			Case  oCF.EntePubblico And !IsEmpty(oCF.CodiceIPA)

				xMessageBox(Thisform.TB_(,'04B3F782-9CCA-4213-8EAF-F03540052E33', [L'anagrafica è dotata di "Codice Ufficio PA". Si necessita l'emissione di una fattura elettronica.]), 16)

				Return .F.

			Case !oCF.EntePubblico And !IsEmpty(oCF.CodiceFPR) And !oCF.FE_Ignore_CodiceFPR

				xMessageBox(Thisform.TB_(,'8BEC1C43-BE3E-461F-819B-04E8CA6BE19B', [L'anagrafica è dotata di "Codice Dest/PEC B2B". Si necessita l'emissione di una fattura elettronica.]), 16)

				Return .F.

		Endcase 	

	EndIf 

EndIf



** Controllo i valori dei campi EXTRA

If !ExtraInfo_QuerySave(This.PF.pgGenerale.PF.pgInfo.cntExtrainfo)

	Return .F.

EndIf 



** Verifico validità per i documenti di Tipo autofattura

If IsEmpty(Thisform.AutoTD_Chk('CF_AUTO4SAVE'))

	Return .F.

Endif



** Verifico validità dati autofattura

If IsEmpty(Thisform.AutoTD_Chk('SAVE'))

	Return .F.

Endif



** Verifico validità dati fatture elettroniche

If IsEmpty(Thisform.Fte_Check('SAVE'))

	Return .F.

Endif



** Verifico congruenza con i dati in Altri Dati Gestionali e Aliquota Iva

If oApp.LicInfo.FatturaElettronica And !This.NDocComm_Check()

	Return .F.

EndIf





Return .T.



ENDPROC

PROCEDURE setpictureqta



LOCAL cPicQta



cPicQta = THISFORM.DE.Preferenza.PicSepQta



WITH ThisForm.PF.pgGenerale.PF.pgRighe

	IF .ControlCount > 0

		.cnt.Grid.ColQta.InputMask 			= cPicQta

		.cnt.Grid.ColQtaEvadibile.InputMask = cPicQta

**		.cnt.Grid.ColQtaEvasa.InputMask 		= cPicQta

	ENDIF

ENDWITH

ENDPROC

PROCEDURE queryedit

LParameters lInsertMode



Local cMsg, oRec, cStmt, lCanEdit, lRefreshNeeded



lCanEdit = DoDefault(lInsertMode, @lRefreshNeeded, 'il documento')

If lRefreshNeeded

	** Disponibile se necessario (vedi Fedi_CGMovT)

EndIf



If lCanEdit



	If lInsertMode And This.PF.pgGenerale.PF.pgEvasioni.ControlCount > 0

		ThisForm.Id_DoTes = -1

	EndIf



	If !lInsertMode



		** Controllo stato modificabile

		If lCanEdit

			If !DoTes.Modificabile And !QuestionBox(RL_INFINITE, "Il documento non è modificabile !!", "modificare il documento")

				lCanEdit = .F.

			EndIf

		EndIf

			

		** Controllo stato evasione

		If lCanEdit		

			Text To cStmt TextMerge NoShow



				Select Top 1

					te.Cd_Do,

					te.DataDoc,

					te.NumeroDoc

				From 	 DoRig r

				Inner Loop Join DoRig re On re.Id_DoRig_Evade = r.Id_DoRig

				Inner Join DoTes te On te.Id_DoTes      = re.Id_DoTes

				Where r.Id_DoTes = << Format4Spt(DoTes.Id_DoTes) >>



			EndText

			oRec = xSqlExec2Obj(cStmt)	

			If Vartype(oRec) == 'O'

				cMsg = "Il documento che si sta modificando" + CRLF + "è già stato evaso dal documento " + CRLF + CRLF + ;

						 "   " + RTrim(oRec.Cd_Do) + ' ' + AllTrim(oRec.NumeroDoc) + ' del ' + DToC(oRec.DataDoc)

				If !QuestionBox(RL_POWER_USER, cMsg, "modificare il documento")

					lCanEdit = .F.

				EndIf

			EndIf

		EndIf



		** Controllo stato contabilizzazione

		If lCanEdit And (oApp.LicInfo.CG_Main Or !CG_Export())

			Text To cStmt TextMerge NoShow

			

				Select Count(*) As Counter

				From CGMovT

				Where Id_DoTes = << Format4Spt(DoTes.Id_DoTes) >> And ProvvisorioDaDocumento = 0		



			EndText

			oRec = xSqlExec2Obj(cStmt)	

			If oRec.Counter > 0 And !QuestionBox(RL_POWER_USER, 'Il movimento contabile associato al documento è già stato contabilizzato', 'modificare il documento')

				lCanEdit = .F.

			EndIf

		EndIf





		** Fattura Elettronica

		If !IsEmpty(DOTes.FTE_Status)

		

			Local oFTEW 

			oFTEW = xSqlExec2Obj('Select InviatoHUB, InviatoSDI, Errore, Emesso, RifiutatoPA From FTE_WorkFlow Where FTE_Status = ' + FormatC4Spt(DOTes.FTE_Status))

			

			Do Case

				Case oFTEW.RifiutatoPA = 1

					xMessageBox('Questo documento elettronico è stata CONSEGNATO al Cliente il quale lo ha rifiutato.' + CRLF + 'Dopo le modifiche che saranno apportate si dovrà procedere con il nuovo invio. Il file XML non sarà modificato pertanto risulterà una discrepanza fra i dati salvati e quelli inviati.' + CRLF + CRLF + ;

								 	   'Confermi la modifica del documento?', 4+32)

				

				

				Case (oFTEW.InviatoHUB = 1 Or oFTEW.InviatoSDI = 1) And oFTEW.Errore = 0 And oFTEW.Emesso = 0

					** Documento INVIATO				

					If xMessageBox('Il documento elettronico risulta in elaborazione.' + CRLF + 'Il file XML non sarà modificato pertanto risulterà una discrepanza fra i dati salvati e quelli inviati.' + CRLF + CRLF + ;

								 	   'Confermi la modifica del documento?', 4+32) = 7

						Return .F.

					EndIf 				



				Case oFTEW.Emesso = 1

					** Documento EMESSO (cioè inviato a SDI senza errori, oppure fatture fornitore registrata da XML ricevuto) 

					If xMessageBox(Iif(DoTes.CliFor = 'C', 'Il documento elettronico risulta TRASMESSO.', Iif(InList(DoTes.TipoDocumento, 'F', 'A'), 'La Fattura', 'La Nota di Accredito') + ' è stata creata da un documento elettronico.') + CRLF + ;

										'Il file XML non sarà modificato pertanto risulterà una discrepanza fra i dati salvati e quelli inviati.' + CRLF + CRLF + ;

								 	   'Confermi la modifica del documento?', 4+32) = 7

						Return .F.

					EndIf				



			EndCase

						

		EndIf 

						

	EndIf



	** -----------------------------------------------------------------------------------------

	** In caso di edit o newdup faccio il controllo dello stato cliente



	Local aStInfo[1]

	AStackInfo(aStInfo)



	If InList(Substr(aStInfo(Program(-1)-2, 3), 14), 'cmdedit', 'cmdnewdup')





		** Controllo lo stato del cliente

		Local oRec, oXml, oGNodes, oGNode

		Local cNoteCliFor, cMsg		

		

		If lCanEdit And This.Pf.PgGenerale.txtCd_CF.Field.CheckFor = 1

				

			oRec = xSqlExec2Obj('Select S.Documenti, S.MessageD, S.AddNoteD, CF.Note_CF, NoteXml = Convert(Varchar(Max), CF.NoteXml) From CF Join CFStato S On S.Cd_CFStato = CF.Cd_CFStato And S.TipoCF = CF.TipoCF Where CF.Cd_CF = ' + FormatC4Spt(DoTes.Cd_CF))

			If Vartype(oRec) = 'O' And oRec.Documenti = 'B'

		

				cNoteCliFor = ''

				Do Case 

					Case oRec.AddNoteD = -1									&& Note Principali

						cNoteCliFor = Nvl(Rtrim(oRec.Note_CF), '')

					

					Case oRec.AddNoteD > 0 And !IsEmpty(oRec.NoteXml)	&& NoteXML					

						oXml = NewDomDocument(oRec.NoteXml)

						oGNodes = oXml.selectNodes('rows/row')

						For Each oGNode In oGNodes	

							If Val(Nvl(oGNode.GetAttribute('nota'), 0)) = oRec.AddNoteD

								cNoteCliFor = Rtrim(oGNode.Text)

								Exit

							EndIf 

						Next 

				EndCase 

		

				If Left(DoTes.Cd_CF, 1) = 'C'

					cMsg = Thisform.TB_(,'9A3F3958-2858-4FD4-A699-A0C6AAFB5567', 'Controllo Anagrafica.' + CRLF + '%1!' + CRLF + '%2!' + CRLF + CRLF + "Vuoi cambiare l'attuale cliente intestatario del documento?"   + CRLF + CRLF + 'Premi "Cambia" per poter modificare il codice cliente, altrimenti "Annulla" per ritornare alla consultazione dei documenti.|Cambia', 	 oRec.MessageD, cNoteCliFor)

				Else

					cMsg = Thisform.TB_(,'ADCB1BFC-83F5-4C4A-B375-92F6FA947BB7', 'Controllo Anagrafica.' + CRLF + '%1!' + CRLF + '%2!' + CRLF + CRLF + "Vuoi cambiare l'attuale fornitore intestatario del documento?" + CRLF + CRLF + 'Premi "Cambia" per poter modificare il codice fornitore, altrimenti "Annulla" per ritornare alla consultazione dei documenti.|Cambia', oRec.MessageD, cNoteCliFor)

				EndIf 

		

				If xMessageBox(cMsg, MB_ICONEXCLAMATION + MB_OKCANCEL) = 1

					This.PF.ActivePage = 2 				

					Thisform.Execasync('Thisform.PF.PgGenerale.txtCd_CF.Field.SetFocus()')

				Else

					lCanEdit = .F.	

				EndIf 

			EndIf 

		EndIf	

		

	EndIf 



EndIf

Return lCanEdit





ENDPROC

PROCEDURE ischanged

IF GETNEXTMODIFIED(0, 'DoRig') > 0

	xMessageBox(Thisform.TB_(,'87C621F3-1943-481F-86D3-F90710C022D3', 'Attenzione: ci sono delle modifiche sulle righe.'))

	RETURN .T.

ENDIF



IF GETNEXTMODIFIED(0, 'DoRigSpesa') > 0

	xMessageBox(Thisform.TB_(,'7FF6C256-52BC-450A-BA66-7F4B562B3F10', 'Attenzione: ci sono delle modifiche sulle spese.'))

	RETURN .T.

ENDIF



RETURN DODEFAULT()





ENDPROC

PROCEDURE onrecordchange

** Considerando che questo codice viene valutato anche durante la consultazione dell'elenco

** risulta un ammazzaperformance inutile visto che comunque con lo skip di record viene

** richiamato il refresh del campo in ogni caso



**	WITH THIS

**		** Forzo il refresh per assicurarmi che l'FKALIAS e la query del controllo al server venga valorizzata!

**		.PF.pgGenerale.txtCd_DO.FIELD.Refresh()

**	ENDWITH	



** se i tipi di doc con cui lavoro sono solo quelli che non posso evadere per definizione

** allora so a priori che non li posso evadere e nascondo il tasto



Local lEnabled

Local cTip, cStmt

Local nBitmaskIVASosp, nBitmaskVietati, nWA



nWA  = Select(0)

cTip = ''

nBitmaskVietati = Bitor(TD_CA_FATTURA		, TD_CA_FATTURA_ACC	, TD_CA_NOTA_ACCREDITO,	;

								TD_CP_FATTURA		, TD_CP_FATTURA_ACC	, TD_CP_NOTA_ACCREDITO,	;

								TD_AD_CARICO_PRD	, TD_AD_RETTIFICA										)



** La DoBitMask qui è a zero quando faccio un nuovo documento. 

** Tuttavia non mi importa perché l'evasione la gestisco solo in Show

lEnabled =		 DoTes.Prelevabile				;

				And DoTes.Esecutivo					;

				And DoTes.RigheEvadibili > 0	 	;

				And Bitor(DoTes.DoBitMask, nBitmaskVietati) != nBitmaskVietati



Text To cStmt TextMerge NoShow

	Select 

		P.Cd_Do_Prelevabile	As Cd_Do_Src,

		P.Cd_Do					As Cd_Do_Dst

		--,Do.Descrizione,

		--,CN.FatturaElettronica

		--,CodiceIpa, CodiceFpr

	From

		DoDoPrel P 

		Inner Join Do On Do.Cd_Do = P.Cd_Do

		Inner Join CN On CN.Cd_CN = Do.Cd_CN

		, (Select EntePubblico, CodiceIpa, CodiceFpr From CF Where Cd_CF = <<FormatC4Spt(DOTes.Cd_CF_Fatt_R)>>) CF

	Where 

		P.Cd_Do_Prelevabile = <<FormatC4Spt(DOTes.Cd_DO)>>

		And (Do.TipoDocumento Not In ('F','A','N') Or ((CodiceIPA Is Null And CodiceFPR Is Null And FatturaElettronica = 0) Or FatturaElettronica = 1))

	Order By 

		P.Cd_Do_Prelevabile, P.Cd_Do	

EndText 

xSqlExec(cStmt, '_DoEvadibilita')



Scan For Cd_Do_Src = DoTes.Cd_Do

	cTip = Textmerge("<<cTip>> / <<Cd_Do_Dst>>")

EndScan



Use In _DoEvadibilita



If !Empty(cTip)

	cTip 		= 'Emetti '+ Substr(cTip,4)

Else

	cTip 		= '...'

	lEnabled = .F.

EndIf



With This.Toolbar.Buttons('DOPUSH')

	.Enabled 		= lEnabled

	.ToolTipText	= cTip

EndWith



** Cliente di fatturazione non visibile per Documenti IVATI

This.PF.PgGenerale.PF.PgGenerale.txtCF_Fatt.Visible = !DoTes.ImportiIvati



This.PF.PgGenerale.PF.pgInfo.edtNotePiede.DoBitMask =  DoTes.DoBitMask



This.ShowHidePeppol()



** Fattura Elettronica

This.Toolbar.Buttons('FTEXML').Enabled  = Thisform.Fte_Isxml()

If PemStatus(This.PF.pgGenerale.PF.pgGenerale, 'cntFactoring', 5)

	This.PF.pgGenerale.PF.pgGenerale.cntFactoring.Refresh()

EndIf 

This.PF.pgGenerale.PF.pgGenerale.cntConservazioneInvio.Refresh()

This.ToolBar.Buttons('FTEVIEW').Enabled = This.Toolbar.Buttons('FTEXML').Enabled And This.PF.pgGenerale.PF.pgGenerale.cntConservazioneInvio.Visible 



If This.ToolBar.IsPresent('FTESEND')

	This.ToolBar.Buttons('FTESEND').Visible = (DOTes.CliFor = 'C')

	This.ToolBar.Buttons('FTESEND').Enabled = DoTes.Esecutivo And (NEvl(DoTes.Fte_Status, '') = '000')

EndIf 



If This.ToolBar.IsPresent('FTE_HUBINSPECTOR')

	This.ToolBar.Buttons('FTE_HUBINSPECTOR').Visible =  This.ToolBar.Buttons('FTESEND').Visible

	This.ToolBar.Buttons('FTE_HUBINSPECTOR').Enabled = DoTes.Esecutivo And !This.ToolBar.Buttons('FTESEND').Enabled And !IsNull(DoTes.Fte_Status)

EndIf 



If This.ToolBar.IsPresent('FTELINK')

	This.Toolbar.Buttons('FTELINK').Enabled = (DOTes.CliFor = 'F' And InList(DOTes.TipoDocumento, 'F', 'A', 'N')) And (!DOTes.FTE_IsInDMS Or DOTes.FTE_CanModify)

	This.Toolbar.Buttons('FTELINK').ToolTipText = Iif(DOTes.FTE_CanModify, 'Sostituisci file XML Fattura Elettronica', 'Collega file XML Fattura Elettronica')

EndIf 



With This.Toolbar.Buttons('VIEWSCADENZA')

	.Enabled 		= InList(DOTes.TipoDocumento, 'F','A','N')

EndWith



** Auto TD functions

This.AutoTD_Bar('RC')

This.AutoTD_Set('UI')



** Extra Info

This.ExtraInfo_Load()



** Evidenziazione page INFO in caso di NoteXML o Attributi

If !IsEmpty(DoTes.NotePiede) Or !IsEmpty(DoTes.NoteXml) Or !IsEmpty(DoTes.Attributi)

	This.PF.pgGenerale.PF.pgInfo.FontBold 		 = .T.

	This.PF.pgGenerale.PF.pgInfo.FontUnderline = .T.

	This.PF.pgGenerale.PF.pgInfo.ForeColor 	 = oApp.MainColor

Else

	This.PF.pgGenerale.PF.pgInfo.FontBold 		 = .F.

	This.PF.pgGenerale.PF.pgInfo.FontUnderline = .F.

	This.PF.pgGenerale.PF.pgInfo.ForeColor 	 = Rgb(0,0,0)

EndIf 





**

Select (nWa)



DoDefault()





ENDPROC

PROCEDURE cmdedit

ThisForm.LockScreen = .T.

DoDefault()

ThisForm.LockScreen = .F.



ENDPROC

PROCEDURE mnu_initactionpad

Lparameters cKey



#Define MB_ACTION_SEPx			1000

#Define MB_ACTION_PREL			1001

#Define MB_ACTION_DETTAGLI		1002

#Define MB_ACTION_REPLICA		1003

#Define MB_ACTION_COPIA_DA		1004

#Define MB_ACTION_SPLITTA		1005

#Define MB_ACTION_SEPy			1006

#Define MB_ACTION_DBCUSTOM		1007

#Define MB_ACTION_DBESPLODI	1008

#Define MB_ACTION_SEPz			1009

#Define MB_ACTION_AUTOTD		1010

#Define MB_ACTION_AUTOTDCOGE	1011

#Define MB_ACTION_AUTOTDFATT	1012

#Define MB_ACTION_AUTOTDVIEW	1013



Local cMenuName, cPopupName, cForm



With This

	cForm			= .Name

	cMenuName  	= This.mnu_GetMenuName ()

	cPopupName 	= This.mnu_GetPopupName(cKey)

Endwith



DoDefault(cKey)



Define Bar MB_ACTION_SEPx 	    Of (cPopupName)	Prompt "\-"

Define Bar MB_ACTION_COPIA_DA	 Of (cPopupName)	Prompt Thisform.TM_(,"93349E9C-1E4E-45D3-B8D1-E3C26A7AB347", "Copia righe da ...")	 	Skip For !&cForm..CmdCopiaDa(.T.)

Define Bar MB_ACTION_PREL 	    Of (cPopupName) 	Prompt Thisform.TM_(,"6073608F-4391-4EF4-B678-D79B743187CF", "Preleva righe ...")		Skip For !&cForm..CmdPreleva(.T.)

Define Bar MB_ACTION_DETTAGLI  Of (cPopupName) 	Prompt Thisform.TM_(,"1761168F-7AF4-4C77-86D1-000DACD5DC0F", "Dettagli")					Skip For !&cForm..CmdDettagli(.T.)

Define Bar MB_ACTION_REPLICA   Of (cPopupName) 	Prompt Thisform.TM_(,"949509AF-2F81-4C4F-8CF6-5B1E8AC0995B", "Replica dati su righe") 	Skip For !&cForm..CmdReplica(.T.)

Define Bar MB_ACTION_SPLITTA   Of (cPopupName) 	Prompt Thisform.TM_(,"DFAE88E9-2E6F-48AA-988F-2C1B6819630E", "Sdoppia riga")			 	Skip For !&cForm..CmdSplitta(.T.)

Define Bar MB_ACTION_SEPy 	    Of (cPopupName)	Prompt "\-"



On Selection Bar MB_ACTION_COPIA_DA	 Of (cPopupName) &cForm..DoCmd('CopiaDa' )

On Selection Bar MB_ACTION_PREL		 Of (cPopupName) &cForm..DoCmd('Preleva' )

On Selection Bar MB_ACTION_DETTAGLI	 Of (cPopupName) &cForm..DoCmd('Dettagli')

On Selection Bar MB_ACTION_REPLICA	 Of (cPopupName) &cForm..DoCmd('Replica' )

On Selection Bar MB_ACTION_SPLITTA	 Of (cPopupName) &cForm..DoCmd('Splitta' )



** ----- LICADAPTER

If (oApp.LicInfo.DO_Ato Or oApp.LicInfo.DB_Varianti)

	Define       Bar MB_ACTION_DBCUSTOM  Of (cPopupName) Prompt Thisform.TM_(,"06631ABE-25B8-40A1-975B-16B2C5E39BC1", "Distinta Custom") Skip For !&cForm..CmdDoDBEdit(, .T.)

	On Selection Bar MB_ACTION_DBCUSTOM	 Of (cPopupName) &cForm..DoCmd('DoDBEdit', '(ThisForm)')

EndIf



If oApp.LicInfo.DB_Main

	Define       Bar MB_ACTION_DBESPLODI Of (cPopupName) Prompt Thisform.TM_(,"620F7C6E-9344-4B2D-84B9-6569578B9472", "Converti in Lista Materiali") Skip For !&cForm..CmdDoDBConverti(.T.)

	On Selection Bar MB_ACTION_DBESPLODI Of (cPopupName) &cForm..DoCmd('DoDBConverti', '(, 1)')

EndIf



If Bitand(This.DOBitMask, TD_CP_FATTURA + TD_CP_FATTURA_ACC + TD_CP_NOTA_ACCREDITO) != 0



	Define Bar MB_ACTION_SEPz Of (cPopupName)	Prompt "\-"



	Define Bar MB_ACTION_AUTOTD Of (cPopupName) Prompt Thisform.TM_(,"DD02BD8D-14DA-4919-84CD-E8B02C9AB2B9", "Genera Integrazione compensativa") Skip For !&cForm..CmdFteAutoTD(.T.)

	On Selection Bar MB_ACTION_AUTOTD Of (cPopupName) &cForm..DoCmd('FteAutoTD')

	

	Define Bar MB_ACTION_AUTOTDVIEW Of (cPopupName)	Prompt Thisform.TM_(,"9F1550D1-EE28-4E5E-B531-191E05A5DCA0", "Visualizza il documento integrativo") Skip For !&cForm..CmdFteAutoTDView(.T.)

	On Selection Bar MB_ACTION_AUTOTDVIEW Of (cPopupName) &cForm..DoCmd('FteAutoTDView')



EndIf



If Bitand(This.DOBitMask, TD_CA_FATTURA + TD_CA_FATTURA_ACC + TD_CA_NOTA_ACCREDITO) != 0



	Define Bar MB_ACTION_SEPz Of (cPopupName)	Prompt "\-"



	Define Bar MB_ACTION_AUTOTDFATT Of (cPopupName)	Prompt Thisform.TM_(,"335BECD8-E5F9-4FAB-BF01-CDAEBAD3CCDF", "Visualizza la fattura di acquisto collegata") Skip For !&cForm..CmdFteAutoTDFatt(.T.)

	On Selection Bar MB_ACTION_AUTOTDFATT Of (cPopupName) &cForm..DoCmd('FteAutoTDFatt')



	If oApp.LicInfo.CG_Main

		Define Bar MB_ACTION_AUTOTDCOGE	Of (cPopupName)	Prompt Thisform.TM_(,"4AFAB6F8-DE8C-4028-9377-F34B81603B71", "Visualizza la cessione compensativa contabile") Skip For !&cForm..CmdFteAutoTDCoge(.T.)

		On Selection Bar MB_ACTION_AUTOTDCOGE	Of (cPopupName) &cForm..DoCmd('FteAutoTDCoge')

	EndIf



EndIf



Return cPopupName



ENDPROC

PROCEDURE initnewrec

LParameters lIsNewDup, lKeepPrimaryCode



DoDefault(lIsNewDup, lKeepPrimaryCode)



Replace 	FTE_Status 	With Null In DoTes



If lIsNewDup



	Replace Id_DoTes		With 0		;

			  NumeroDoc		With ''		;

			  NumeroDocRif With ''		;

			  DataDocRif	With {}		;

	In DoTes

	

Else



	Replace Esecutivo			With .T.	;

			  Prelevabile		With .T.	;

			  Modificabile		With .T.	;

			  ModificabilePdf With .T.	;

			  CGCorrispondenzaIvaMerce With Impostazione.CGCorrispondenzaIvaMerce ;

	In DoTes

	

EndIf

ENDPROC

PROCEDURE runreport

LParameters nAction, cUd_ReportDoc



If This.PF.ActivePage = 1

	DoDefault(nAction)

Else

	If IsEmpty(cUd_ReportDoc) And !InList(nAction, RE_ACT_PRINT_TO_SCREEN, RE_ACT_PRINT_TO_PRINTER)

		If Eof('DOReport')

			Go Top In DOReport

		EndIf

		If !Eof('DOReport') And !Empty(DOReport.Ud_ReportDoc)

			This.PrintDocument(DoTes.Id_DoTes, nAction, DOReport.Ud_ReportDoc)			

		EndIf 

	Else

		This.PrintDocument(DoTes.Id_DoTes, nAction, cUd_ReportDoc)	

	EndIf

EndIf



ENDPROC

PROCEDURE edit

LParameters lInsert, oRecDup



Local oChoice, nWA, cId_DoDB

Local nDoRigRecNo, nDoRigSpesaRecNo



** DEFECT 203779 : nel save è stato forzato il RecSignClear, qua devo fare il refresh delle grid

This.PF.pgGenerale.PF.pgRighe.cnt.Grid.Refresh()

This.PF.pgGenerale.PF.pgPiede.cnt.cntFattura.Grid.Refresh()



**

nDoRigRecNo			= Recno('DORig')

nDoRigSpesaRecNo	= Recno('DORigSpesa')



This.DE.DoRig.MakeIndex('Riga')

This.DE.DoRigSpesa.MakeIndex('Riga')

This.DE.DoRigPackList.MakeIndex('PackListref', 'Elemento')

This.DE.DoRigPackList.MakeIndex('Id_DoRig')

This.DE.DoRigPackList.MakeIndex('Riga')

This.DE.DoRigPackList.RunCmd   ('Set Filter To')



Replace Riga With Recno('DoRig'         ) For Riga != Recno('DoRig'         ) In DoRig

Replace Riga With Recno('DoRigSpesa'    ) For Riga != Recno('DoRigSpesa'    ) In DoRigSpesa

Replace Riga With Recno('DoRigPackList' ) For Riga != Recno('DoRigPackList' ) In DoRigPackList



cId_DoDB = 'Null'



If !IsNull(oRecDup)



	nWA = Select(0)



	xSqlExec(This.DE.DoRig.BuildRequeryStmt("DoRig.Id_DoTes = " + Format4Spt(oRecDup.Id_DoTes)), '_Tmp_')

	This.DE.DoRig.AppendFrom(Dbf('_Tmp_'),,.T.)

	Use In _Tmp_



	oChoice = This.RunNewDupChoice('NewDupChoice', 'Fedi_DocCommon', Thisform)

	If oChoice.WasConfirmed

	

		If oChoice.chkDistinte.Value

			ThisForm.CmdDoDBNewDup()

			cId_DoDB = 'Id_DoDb'

		EndIf



		If !oChoice.chkMatricole.Value

			Replace Matricole With Null For !IsEmpty(Matricole) In DoRig	

		EndIf



		If oChoice.chkPacking.Value

			xSqlExec(This.DE.DoRigPackList.BuildRequeryStmt("DoRigPackList.Id_DoRig In (Select Id_DoRig From DoRig Where Id_DoTes = " + Format4Spt(oRecDup.Id_DoTes) + ")"), '_Tmp_')

			Scan

				Select DoRig

				Locate For Id_DoRig = _Tmp_.Id_DoRig

				Select _Tmp_

				Replace Id_DoRig With RecNo('DoRig')

			EndScan

			Replace All Id_DoRigPackList With 0 In _Tmp_

			This.DE.DoRigPackList.AppendFrom(Dbf('_Tmp_'),,.T.)

			Use In _Tmp_

		EndIf

		

		If !oChoice.chkAttributi.Value

			Replace Attributi With Null In DoTes

			This.PF.pgGenerale.PF.pgInfo.cntAttributi.Refresh()

		EndIf		



		If oChoice.chkExtraInfo.Value = .F.

			Replace ExtraInfo With .Null. In DoTes

			This.Extrainfo_Load()

		EndIf 

		

	EndIf

	oChoice.Release()

	

	Replace All Id_DoRig With 0 In DoRig



	Select DoRig

	Replace All Id_DoDB With &cId_DoDB, Id_DoRig_Evade With Null, QtaEvasa With 0, QtaEvadibile With Qta



	xSqlExec(This.DE.DoRigSpesa.BuildRequeryStmt("DoRigSpesa.TipoRigaSpesa != 'Z' And DoRigSpesa.Id_DoTes = " + Format4Spt(oRecDup.Id_DoTes)), '_Tmp_')

	Replace All Id_DoRigSpesa With 0 In _Tmp_

	This.DE.DoRigSpesa.AppendFrom(Dbf('_Tmp_'),,.T.)

	Use In _Tmp_

	

	Select DoRigSpesa

	Replace All Id_DoRigSpesa_Evade With Null, ImportoEvasoV With 0, ImportoEvadibileV With ImportoV



	Replace Ud_FTE With Null In DoTes

	Replace Id_FactoringProject With Null, FactoringEvent With Null In DoTes

	If PemStatus(This.PF.pgGenerale.PF.pgGenerale, 'cntFactoring', 5)

		This.PF.pgGenerale.PF.pgGenerale.cntFactoring.Refresh()

	EndIf 

	

	Select (nWA)



	If oApp.LicInfo.FatturaElettronica Or oApp.LicInfo.FatturaElettronicaPassiva

		Thisform.Toolbar.Buttons('FTEXML').Enabled  = Thisform.Fte_Isxml()

	EndIf



Else



	If lInsert

	

		** In inserimento di un nuovo articolo, propongo i valori di default per le Extra Info...

		Local cExtraInfo

		cExtraInfo = ExtraInfo_GetDefaultValue('DoTesExtraInfo')

		If !IsEmpty(cExtraInfo)

			Replace ExtraInfo With cExtraInfo In DoTes

			This.Extrainfo_Load()

		EndIf 

			

	EndIf 



EndIf



DoDefault(lInsert, oRecDup)



Try

	Go (nDoRigRecNo) 		 In DORig

	Go (nDoRigSpesaRecNo) In DORigSpesa

Catch

EndTry 



With This.PF.pgGenerale



	.PF.pgRighe.Cnt.Grid.AllowAddNew					= .T.

	.PF.pgPiede.Cnt.cntFattura.Grid.AllowAddNew	= .T.

	.PF.pgModuli.Cnt.Grid.AllowAddNew				= .T.

	.PF.pgPiede.Cnt.TipoSpesaDisplay(.txtCd_Do.Field.FKRecord.TipoDocumento, lInsert)



	This.DE.DoRigPackList.RunCmd ('SET FILTER TO Id_DoRig = xDefault(DoRig.Id_DoRig, RECNO("DoRig"))')



	.PF.pgGenerale.cntDatiContabili.txtBic.Field.ReadOnly = .PF.pgGenerale.cntDatiContabili.txtIban.Field.IsITalian()



EndWith





ENDPROC

PROCEDURE onmodechange

LParameters nOldMode, lShowMode, lInsMode, lInsNewDupMode



DoDefault(nOldMode, lShowMode, lInsMode, lInsNewDupMode)



If lInsMode

	** Bug 1084

	** In alcuni casi particolari (nuovo subito dopo aver completato nuovo con registrazione) non viene 

	** scatenato l'OnRefresh()

	This.PF.pgGenerale.txtCd_Do.Field.ValueOnGotFocus = ''

Endif



If !lShowMode

	This.PF.pgGenerale.PF.DynamicPageInitAll()

EndIf



With This.PF.pgGenerale



	If lShowMode

		.txtCd_Do.Field.Enabled = .T.

		.txtCd_VL.Field.Enabled = .T.

	Else

		This.CopiaDataConsegna = !IsEmpty(DoTes.DataConsegna)

		If !lInsMode

			.txtCd_DO.Field.Enabled = .F.

			.txtCd_VL.Field.Enabled = .F.

		EndIf

	EndIf



	.cntTesta2.lblAlert.Visible = .F.		&& nascondo l'alert; sarà cura del txtCd_CF renderlo visibile....



EndWith



With This.PF.pgGenerale.PF



	.pgGenerale.cntStato.chkEsecutivo.Enabled = ;

			lShowMode Or ;								&& In Show

			lInsMode  Or ;								&& In inserimento

			Oldval('Esecutivo', 'DoTes') = .F. 	&& In modifica solo se era .f.



	If .pgRighe.ControlCount > 0

		With .pgRighe.Cnt.Grid	

			.AllowAddNew                       = !lShowMode

			.colDistinta.btnNoDistinta.Enabled = !lShowMode

			If lShowMode

				.ColCAPartenza.Header1.Caption = 'Inizio COAN'

				.ColCAPartenza.ControlSource 	 = "CMonthYearIt(GoMonth(Thisform.CA_Datarif(), DoRig.CAPartenza))"

				.ColCAPartenza.CurrentControl	 = 'text1'

				.ColCADurata.Header1.Caption 	 = 'Fine COAN'

				.ColCADurata.ControlSource 	 = "CMonthYearIt(GoMonth(Thisform.CA_Datarif(), DoRig.CAPartenza + DoRig.CADurata - 1))"

			Else

				.ColCAPartenza.Header1.Caption = 'Partenza'

				.ColCAPartenza.ControlSource 	 = 'DoRig.CAPartenza'

				.ColCAPartenza.CurrentControl	 = 'Cmb_CAOfs'

				.ColCADurata.Header1.Caption 	 = 'Durata in mesi'

				.ColCADurata.ControlSource 	 = 'DoRig.CADurata'

			EndIf

		EndWith

	EndIf



	If .pgPiede.ControlCount > 0

	

		Local oChkSpeseBolli, oDoRec, oCFRec

		oDoRec 			= .Parent.txtCd_Do.Field.FKRecord

		oCFRec			= .Parent.txtCd_CF.Field.FKRecord

		oChkSpeseBolli = .pgPiede.Cnt.cntFattura.chkSpeseBolli

		oChkSpeseBolli.Visible = !lShowMode And oCFRec.Cliente And oDoRec.TipoDocumento $ 'FAN'	&& Verrebbe inizializzato nell'OnValueChange del tipo documento, ma in Nuovo con duplicazione non basta.

		oChkSpeseBolli.Value   = oChkSpeseBolli.Visible And Thisform.GetSpeseBolliFlag()



		With .pgPiede.Cnt.CntFattura.Grid

			.AllowAddNew                      = !lShowMode

			If lShowMode

				.colCAPartenza.Header1.Caption = 'Inizio Comp.'

				.colCAPartenza.ControlSource 	 = "CMonthYearIt(GoMonth(Thisform.CA_Datarif(), DoRigSpesa.CAPartenza))"

				.colCAPartenza.CurrentControl	 = 'text1'

				.colCADurata.Header1.Caption 	 = 'Fine Comp.'

				.colCADurata.ControlSource 	 = "CMonthYearIt(GoMonth(Thisform.CA_Datarif(), DoRigSpesa.CAPartenza + DoRigSpesa.CADurata - 1))"

			Else

				.colCAPartenza.Header1.Caption = 'Partenza'

				.colCAPartenza.ControlSource 	 = 'DoRigSpesa.CAPartenza'

				.colCAPartenza.CurrentControl	 = 'Cmb_CAOfs'

				.colCADurata.Header1.Caption 	 = 'Durata in mesi'

				.colCADurata.ControlSource 	 = 'DoRigSpesa.CADurata'

			EndIf

		EndWith



		** BUG 2149

		With .pgPiede.Cnt.CntDDT

			.txtPesoLordo.btnSommaPesoLordo.Visible 	= !lShowMode

			.txtPesoNetto.btnSommaPesoNetto.Visible	= !lShowMode

			.txtVolume.btnSommaVolume.Visible			= !lShowMode

			.txtColli.btnSommaColli.Visible				= !lShowMode And !Empty(Evaluate(ThisForm.PF.pgGenerale.txtCd_DO.FIELD.FKAlias+ '.PkLstEnabled'))		&& Thisform.Mode != FEDIMODE_SHOW 

		EndWith		

		

	EndIf 



	.ActivePage      = Iif(lInsMode, 1, .ActivePage)

	.RefreshAllPages = !lShowMode	

	.CurrentPage.Refresh()	&& Correzione Bug 559

	

EndWith



This.ShowHidePeppol()



** se i tipi di doc con cui lavoro sono solo quelli che non posso evadere per definizione

** allora so a priori che non li posso evadere e nascondo il tasto

Local lForseEvadibili, nBitmaskVietati

nBitmaskVietati = Bitor(	;

								TD_CA_FATTURA		, TD_CA_FATTURA_ACC	, TD_CA_NOTA_ACCREDITO,	;

								TD_CP_FATTURA		, TD_CP_FATTURA_ACC	, TD_CP_NOTA_ACCREDITO,	;

								TD_AD_CARICO_PRD	, TD_AD_RETTIFICA										;

							  )

lForseEvadibili = !( Bitor(This.DoBitMask, nBitmaskVietati) == nBitmaskVietati )



** DI - Abilito UI

Iif(lShowMode And nOldMode != Thisform.Mode, This.DoIntento_Visible(.T.), .T.)



With This.Toolbar



	.Buttons('ROWADD').Visible 				= !lShowMode

	.Buttons('ROWDEL').Visible 				= !lShowMode

	.Buttons('ROWINS').Visible 				= !lShowMode

	.Buttons('SEP_AFTER_ROWMARK').Visible	= !lShowMode

	.Buttons('ROWDOWN').Visible 				= !lShowMode

	.Buttons('ROWUP').Visible 					= !lShowMode

	.Buttons('SEP_AFTER_ROWUP').Visible		= !lShowMode

	.Buttons('ROWCOPY').Visible 				= !lShowMode

	.Buttons('ROWPASTE').Visible 				= !lShowMode

	.Buttons('SEP_AFTER_ROWPASTE').Visible	= !lShowMode

	.Buttons('DOPUSH').Visible 				=  lShowMode And lForseEvadibili

	.Buttons('SEP_AFTER_DOPUSH').Visible	=  lShowMode And lForseEvadibili	

	.Buttons('VIEWSCADENZA').Visible			= !lInsMode

	

	If oApp.LicInfo.CG_Main

		.Buttons('VIEWINTRA').Visible				= !lInsMode

		.Buttons('VIEWCG').Visible					= !lInsMode

	EndIf



	If .IsPresent('FTESEND')

		.Buttons('FTESEND').Visible				= lShowMode

	EndIf  

	If .IsPresent('FTE_HUBINSPECTOR')

		.Buttons('FTE_HUBINSPECTOR').Visible	= lShowMode

	EndIf

	If .IsPresent('FTELINK')

		.Buttons('FTELINK').Visible				= lShowMode

	EndIf  



EndWith



** Auto TD fuctions

This.AutoTD_Bar('MC')

This.AutoTD_Set('UI')



** Extra Info

This.Extrainfo_Load()



** Factoring

If PemStatus(This.PF.pgGenerale.PF.pgGenerale, 'cntFactoring', 5) 

	This.PF.pgGenerale.PF.PgGenerale.cntFactoring.btnInvia.Enabled = lShowMode	

	This.PF.pgGenerale.PF.PgGenerale.cntFactoring.refresh()

EndIf 



ENDPROC

PROCEDURE cmdpreview

With ThisForm.PF.pgGenerale.PF

	If .pgModuli.ControlCount = 0

		.DynamicPageInit(.pgModuli)

		.pgModuli.Refresh()

	EndIf

EndWith



DoDefault()



ENDPROC

PROCEDURE cmdprint

With ThisForm.PF.pgGenerale.PF

	If .pgModuli.ControlCount = 0

		.DynamicPageInit(.pgModuli)

		.pgModuli.Refresh()

	EndIf

EndWith

	

DoDefault()



ENDPROC

PROCEDURE cmdnewdup

** Controllo il fido prima della duplicazione



Local vRet, oDoRec, oFormFido, oCF



vRet = 1

oDoRec = xSqlExec2Obj('Select UIchkFido, UIchkFidoBo, UIchkFidoOC, UIchkFidoVis, UIchkFidoBlk, UIChkFidoBlkE From DO Where Cd_DO = ' + FormatC4Spt(DOTes.Cd_DO))

** fatturazione

oCF = xSqlExec2Obj('Select Cd_CF, Fido From CF Where Cd_CF = ' + FormatC4Spt(DOTes.Cd_CF_Fatt))

** intestatario (eventualmente)

oCF = Iif(!IsEmpty(oCF), oCF, xSqlExec2Obj('Select * From CF Where Cd_CF = ' + FormatC4Spt(DOTes.Cd_CF)))

If oDoRec.UIchkFido And oCF.Fido != 0

	** Non passo il totale documento che non esiste

**	oFormFido = NewObjectWCR7('ControlloFido', 		'Forms\Fedi_DocCommon.vcx', '',	oCF.Cd_CF, !oDoRec.UIchkFidoBo, !oDoRec.UIchkFidoOC, , oDoRec.UIchkFidoBlk, ThisForm.DoBitmask)				

	oFormFido = NewObjectWCR5('ControlloFido_Ahts', 'Forms\Fedi_DocCommon.vcx', '',	oCF.Cd_CF, !oDoRec.UIchkFidoBo, !oDoRec.UIchkFidoOC)



	If Vartype(oFormFido) = 'O'

		If oDoRec.UIchkFidoVis Or oFormFido.Differenza < 0

			oFormFido.Show(1)

			Inkey(0.1, "H")

		EndIf

		If oFormFido.Differenza < 0

			If oDoRec.UIchkFidoBlk

				xMessageBox(Thisform.TB_(,'41B910D1-2DA4-4040-9CE1-1A660120BA93', "Emissione Bloccata a causa del superamento del fido!!"), MB_ICONSTOP)

				vRet = 0

			Else

				If xMessageBox(Thisform.TB_(,'05D02541-12B5-4389-B0A7-65C0004FCE66', "Il fido è stato superato!! Si vuole proseguire ugualmente ?"), MB_YESNO + MB_ICONQUESTION + MB_DEFBUTTON2) = IDNO

					vRet = 0

				Else

					If oDoRec.UIChkFidoBlkE And DoTes.Prelevabile && Se già Prelevabile = .F. (es in modifica) non stresso l'operatore...

						xMessageBox(Thisform.TB_(,'5040EFA8-5006-4BB7-92AB-8FABBD0A9E3B', 'Il documento viene impostato come non prelevabile causa superamento del fido.'), MB_ICONINFORMATION)

						Thisform.PF.pgGenerale.PF.pgGenerale.cntStato.chkPrelevabile.SetValue(.F.)

					EndIf

				EndIf

			EndIf

		EndIf

		oFormFido.Release()

	EndIf

EndIf



IF vRet = 0

	RETURN .F.

else

	DODEFAULT()

endif

ENDPROC

PROCEDURE cmdnew

Local cStmt

Local nOldWA



If !DoDefault()

	Return .F.

EndIf 



** ----------------------------------------------



Do Case



	Case IsNull(This.oRecPrev)



		** Controllo se per questa tipologia documenti esiste solo un codice CD_DO

		** NB.: questa parte viene eseguita solo al primo inserimento

		

		nOldWA = Select(0)

		cStmt  = Strtran(This.Pf.PgGenerale.txtCd_Do.Field.FkSelect, 'Do.Cd_Do = <TEXT>', '1=1')



		xSqlExec(cStmt, 'curDO')

		If Reccount('curDO') = 1

			This.PF.PgGenerale.txtCd_DO.Field.SetValue(curDO.Cd_DO, .T.)

			This.AddProperty('Unique_Cd_DO', curDO.Cd_DO)

		EndIf



		Use In Select('curDO')

		Select (nOldWA)



	Case PemStatus(This, 'Unique_Cd_DO', 5)

	

		** Per i successivi inserimenti, se esiste una solo tipologia di Cd_DO, la propongo in automatico

		** NB.: questa parte potrà essere eseguita solo dal secondo inserimento...



		This.PF.PgGenerale.txtCd_DO.Field.SetValue(This.Unique_Cd_DO, .T.)		&& il field Cd_DO viene subito validato e si viene posizionati sul field Cd_CF

	

	Otherwise

	

		** Propongo l'ultimo codice documento utilizzato (vedi metodo .Save )

		**  NB.: questa parte potrà essere eseguita solo dal secondo inserimento...

	

		This.PF.PgGenerale.txtCd_DO.Field.AddProperty('ValueOnRecPrev', This.oRecPrev.Cd_DO) 	&& si ha solo il valore proposto sul field Cd_DO: si può modificarlo o confermalo con il TAB

	

EndCase

ENDPROC

PROCEDURE delete

Local nEntityId

Local lIsFEPassiva

Local oFTEInBox



nEntityId 	 = DOTes.Id_DOTes

lIsFEPassiva = Left(DOTes.Cd_CF, 1) = 'F' And InList(DOTes.TipoDocumento, 'F','A','N')



**

oFTEInBox = CreateObject('Empty')

AddProperty(oFTEInBox, 'IdFatturaRx', xSqlExec2Var("Select IdFatturaRx From DmsDocument Where EntityTable = 'DOTes' And EntityId = " + FormatI4Spt(nEntityId)+ " And Tag = 'FTE'"))

AddProperty(oFTEInBox, 'RicevutaIl' , DOTes.DataDoc)



**

If !DoDefault()

	Return .F.

EndIf 



If oApp.LicInfo.Allegati

	oApp.Dms.DeleteByEntity('DOTes', nEntityId)

EndIf 



** 29-08-2018 Si è deciso di cancellare il record DMS della FTE Passiva sempre, sia che ci sia o meno il modulo DMS.

If lIsFEPassiva

	oApp.Dms.DeleteFEPassiva('DOTes', nEntityId, oFTEInBox)

EndIf 



ENDPROC

PROCEDURE onfirstactivate

DoDefault()



If This.Parameters.ParamCount = 1 And Type('This.Parameters.Param1') = 'O' And PemStatus(This.Parameters.Param1, 'FTE_Import', 5)

	** La form è stata chiamata dalla cmd_fte_import

	

	Local oInfo

	oInfo = This.Parameters.Param1



	** Cerco di bloccare la form Cmd_FTE_Import

	oInfo.CallerForm.LockForm()



	** Inserisco una nuova registrazione

	This.cmdNew()

	This.PF.pgGenerale.txtCd_DO	.Field.SetValue(oInfo.Cd_DO)

	This.PF.pgGenerale.txtCd_CF	.Field.SetValue(oInfo.Cd_CF)

	This.PF.pgGenerale.txtDataDoc .Field.SetValue(oInfo.DataReg)



	This.PF.pgGenerale.PF.pgGenerale.txtNumeroDataRif.Field .SetValue(oInfo.NumeroDocRif)

	This.PF.pgGenerale.PF.pgGenerale.txtNumeroDataRif.Field1.SetValue(oInfo.DataDocRif)



EndIf 



**

This.Extrainfo_Load()



**

If PemStatus(This, 'zoom_IncreaseW', 5) And PemStatus(This, 'RestoreColumnsWidthToLayoutSet', 5) And This.RestoreColumnsWidthToLayoutSet

	** se è attivo lo zoom, devo ripristinare la larghezza delle colonne, altrimenti me le trovo aumentate perchè succede questa serie di eventi:

	** - si avvia la fedi_doc nascosta

	** - nell'init del pgRighe.cnt viene fatto il layouset della grid (quindi le colonne vengono allargate)

	** - nel .Zoom il font delle colonne viene aumentato, e le colonne si allargato ancora...

	**

	** l'esecuzione del seguente codice fa in modo di ripristinare le dimensioni corrette (con il font già modificato dallo zoom)

	If PemStatus(Thisform.PF.pgGenerale.PF.pgRighe, 'cnt', 5)

		Thisform.PF.pgGenerale.PF.pgRighe.cnt.Grid.InitAutoSaveLayout()

	EndIf 

	If PemStatus(Thisform.PF.pgGenerale.PF.pgPiede, 'cnt', 5)

		Thisform.PF.pgGenerale.PF.pgPiede.cnt.cntFattura.Grid.InitAutoSaveLayout()

	EndIf 

EndIf 

ENDPROC

PROCEDURE Destroy

If This.Parameters.ParamCount = 1 And Type('This.Parameters.Param1') = 'O' And PemStatus(This.Parameters.Param1, 'FTE_Import', 5)

	** La form è stata chiamata dalla cmd_fte_import

	This.Parameters.Param1.CallerForm.UnLockForm()

EndIf 



DoDefault()

ENDPROC

PROCEDURE cmdannulla

DoDefault()



If This.Parameters.ParamCount = 1 And Type('This.Parameters.Param1') = 'O' And PemStatus(This.Parameters.Param1, 'FTE_Import', 5)

	** La form è stata chiamata dalla cmd_fte_import

	This.cmdExit()

EndIf 

ENDPROC

PROCEDURE cmdsave

Local lRet, lInsMode



lInsMode = (This.Mode = FEDIMODE_INS)



lRet = DoDefault()



If lInsMode And  This.Mode = FEDIMODE_SHOW

	** Se l'inserimento è andato a buon fine

	If This.Parameters.ParamCount = 1 And Type('This.Parameters.Param1') = 'O' And PemStatus(This.Parameters.Param1, 'FTE_Import', 5)

		** La form è stata chiamata dalla cmd_fte_import



		** Salvo nel DMS l'xml da cui ho generato tale movimento

		This.Parameters.Param1.CallerForm.oEng.CreateDocument_Other(DoTes.Id_DoTes, .T.)



		**

		This.DE.DOTes.RequeryCurrent()

		This.OnRecordChange()

		This.Toolbar.Buttons('NEW').Visible = .F.

	EndIf 

EndIf 



Return lRet

ENDPROC

PROCEDURE statusbar.Refresh

*** ActiveX Control Method ***



ENDPROC

PROCEDURE title_bar.onlabelclick

IF ThisForm.Mode = FEDIMODE_SHOW

	DODEFAULT()

ENDIF



ENDPROC

PROCEDURE PF.pgAllegati.Init

This.AddProperty('IgnoreDynamicPageInitAll', .T.)



DoDefault()

ENDPROC

PROCEDURE PF.dynamicpageinit

LParameters oPage

 

If Lower(oPage.Name) = 'pgallegati' And oPage.ControlCount = 0

	Dms_PgAllegatiInit(oPage, 'DOTES', 'DOTes.Id_DOTes')

EndIf





ENDPROC

PROCEDURE PF.onpageactivate

LParameters oPage, nOldPage, lJustRefreshed



DoDefault(oPage, nOldPage, lJustRefreshed)



With ThisForm.Toolbar



	If Lower(oPage.Name) == 'pgelenco'

		.Buttons('DELETE' ).Enabled 		= .T.

		.Buttons('DELETE' ).MixedState   = .F.

		.Buttons('PRINT'  ).ToolTipText	= 'Stampa Elenco'

		.Buttons('PREVIEW').ToolTipText	= 'Anteprima Elenco'

	EndIf



	If Lower(oPage.Name) == 'pggenerale'

		

		.Buttons('PRINT'  ).Enabled = .T.

		.Buttons('PREVIEW').Enabled = .T.

		.Buttons('PRINT'  ).ToolTipText	= 'Stampa Documento'

		.Buttons('PREVIEW').ToolTipText	= 'Anteprima Documento'

		

		oPage.PF.OnPageActivate(oPage.PF.Pages(oPage.PF.ActivePage))

 

		** Devo forzare la prima chiamata quando attivo la pagina

		Thisform.SetRegimeIva('USERINTERFACE')



		** Defect 252769

		oPage.cntTesta2.Refresh()

		**oPage.txtCd_CF_Auto.Refresh()

		**oPage.txtCd_CF.Refresh()

				

	EndIf



EndWith



ENDPROC

PROCEDURE PF.onpagedeactivate

Lparameters oPage



** Problema TToD() con pagina OWC Debugout {^2005-04-25 00:00:00}, Ttod({^2005-04-25 00:00:00}) torna il giorno prima

_FPReset()



DoDefault(oPage)

ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgGenerale.txtQta) ***
*** PROPERTIES ***
Comment = "6C4FEF13-2966-4C01-AE04-982C04DFE85A"

Alignment = 1

ControlSource = "DORig.Qta"

Height = 19

Left = 0

Top = 11

Width = 92

Name = "Field"


*** METHODS ***
PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC

PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgGenerale.TxtId_MGMov_Carico) ***
*** PROPERTIES ***
Comment = "903F331B-D841-44C2-8636-8D165F033519"

Alignment = 1

ControlSource = "DORig.Id_MGMov_Carico"

Height = 19

InputMask = "#,###,###,###"

Left = 0

Top = 11

Width = 92

Name = "Field"


*** METHODS ***
PROCEDURE KeyPress

LParameters nKeyCode, nShiftAltCtrl



If nKeyCode = -2 																&& F3 - Fast Search

	This.ContextMenuProc(CMM_PROCESS_CHOICE, MB_EDIT_SRCHSPEC0)	

	NoDefault

	Return .T.

EndIf



If (nKeyCode = 67 Or nKeyCode = 99) And nShiftAltCtrl = 0 		&& c - Cancella riferimento riga

	This.ContextMenuProc(CMM_PROCESS_CHOICE, MB_EDIT_SRCHSPEC1)

	NoDefault

	Return .T.

EndIf



Return DoDefault(nKeyCode, nShiftAltCtrl)



ENDPROC

PROCEDURE contextmenuproc

Lparameters nCBMId, xPar1, lFromCode



** Questo codice viene richiamato la prima volta dal menu (con lFromCode == .F.); la chiamata da menu

** deve essere rigirata nel metodo centralizzato Grid_ContextMenuProc,  che poi provvede a richiamare

** questo metodo, stavolta con lFromCode == .T. in modo da evitare la ricorsione



If !lFromCode

	Return Thisform.CallerCntGrid.Grid_ContextMenuProc(This, .F., nCBMId, xPar1)

Else

	Return DoDefault(nCBMId, xPar1)

Endif





ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC

PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgGenerale.txtQtaEvasa) ***
*** PROPERTIES ***
Comment = "6A441C91-2C84-496F-B59C-ADDC14DFA19D"

Alignment = 1

ControlSource = "DORig.QtaEvasa"

Height = 19

Left = 0

Top = 11

Width = 92

Name = "Field"


*** METHODS ***
PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgGenerale.txtQtaEvadibile) ***
*** PROPERTIES ***
Comment = "7C34DD6A-CDA0-40F4-A5BF-FE268E97B7D7"

Alignment = 1

ControlSource = "DORig.QtaEvadibile"

Top = 11

Width = 92

Name = "Field"


*** METHODS ***
PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgGenerale.txtDescrizione) ***
*** PROPERTIES ***
Comment = "D9A9EA10-073D-4A92-B697-2788FC8E551F"

Anchor = 10

ControlSource = "DORig.Descrizione"

Top = 11

Width = 384

Name = "Field"


*** METHODS ***
PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Thisform.SetTitleValue()

Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)





ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgGenerale.TxtCd_ar) ***
*** PROPERTIES ***
ControlSource = "DORig.Cd_AR"

Height = 19

Left = 0

Top = 11

Width = 113

fkhasdisplay = .T.

Name = "Field"


*** METHODS ***
PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



** Ripulisco la caption delle Note...

Thisform.PF.PgGenerale.TxtNote.Title.Caption = Strtran(Thisform.PF.PgGenerale.TxtNote.Title.Caption, ' [CTRL+N: riporta note articolo]', '')



If !IsEmpty(This.FKRecord.Note_AR)

	Thisform.PF.PgGenerale.TxtNote.Title.Caption = Thisform.PF.PgGenerale.TxtNote.Title.Caption + ' [CTRL+N: riporta note articolo]'

Endif



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC

PROCEDURE fkgetcodcf

Return ThisForm.CallerCntGrid.Grid.ColCd_AR.StdText1.fkGetCodCF()



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If This.ReadOnly 

	Return .T.

EndIf



If Empty(DoDefault(lIsChanged, xOldValue))

	** BUG 602 --> per prevenire l'inserimento di un codice bloccato uscendo dalla form lo pulisco

	This.Value = ''

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgGenerale.txtCd_ARMisura) ***
*** PROPERTIES ***
ControlSource = "DORig.Cd_ARMisura"

Height = 19

Left = 0

Top = 11

Width = 29

fktabledesc = Unità di misura

fkdecodedfield = Descrizione

fkhasdisplay = .T.

Name = "Field"


*** METHODS ***
PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC

PROCEDURE fkgetcodar

Return DORig.Cd_AR

ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgGenerale.txtFattoreToUM1) ***
*** PROPERTIES ***
Comment = "9E7818CA-8402-4889-AB55-A64E9ACED351"

ControlSource = "DORig.FattoreTOUM1"

Height = 19

InputMask = "#,###.#####"

Left = 0

Top = 11

Width = 62

Name = "Field"


*** METHODS ***
PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgGenerale.txtCd_MG_P) ***
*** PROPERTIES ***
ControlSource = "DORig.Cd_MG_P"

Left = 0

TabIndex = 2

Top = 12

Width = 48

fktabledesc = Magazzini

fkdecodedfield = Descrizione

fkhasdisplay = .T.

fkacceptinvalid = .F.

Name = "Field"


*** METHODS ***
PROCEDURE fkgetcodar

Return DORig.Cd_AR



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC

PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC

PROCEDURE fkgetcodmges

Return DOTes.Cd_MGEsercizio



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgGenerale.txtCd_MG_A) ***
*** PROPERTIES ***
ControlSource = "DORig.Cd_MG_A"

Height = 19

Left = 0

TabIndex = 2

Top = 11

Width = 48

fktabledesc = Magazzini

fkdecodedfield = Descrizione

fkhasdisplay = .T.

fkacceptinvalid = .F.

Name = "Field"


*** METHODS ***
PROCEDURE fkgetcodar

Return DORig.Cd_AR



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC

PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC

PROCEDURE fkgetcodmges

Return DOTes.Cd_MGEsercizio



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgGenerale.txtCd_ARLotto) ***
*** PROPERTIES ***
ControlSource = "DORig.Cd_ARLotto"

Height = 19

Left = 0

Top = 11

Width = 92

fktabledesc = Lotti

fkdecodedfield = Descrizione

canchangemg = .T.

Name = "Field"


*** METHODS ***
PROCEDURE autoinsertinit

Lparameters oParam



DoDefault(oParam)



oParam.ARLotto.Cd_CF	= DOTes.Cd_CF

ENDPROC

PROCEDURE fkgetcodmges

Return DOTes.Cd_MGEsercizio



ENDPROC

PROCEDURE onvaluepick

LParameters nSearchFormType, xValue4Value, oSelectedRec, lFromCode



** Questo codice viene richiamato la prima volta dal menu (con lFromCode == .F.); la chiamata da menu

** deve essere rigirata nel metodo centralizzato Grid_OnValuePick, che poi provvede a richiamare

** questo metodo, stavolta con lFromCode == .T. in modo da evitare la ricorsione



If !lFromCode

	Return Thisform.CallerCntGrid.Grid_OnValuePick(This, .T., nSearchFormType, xValue4Value, oSelectedRec)

Else

	Return DoDefault(nSearchFormType, xValue4Value, oSelectedRec)

EndIf



ENDPROC

PROCEDURE fkgetcodar

Return DoRig.Cd_AR

ENDPROC

PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)

ENDPROC

PROCEDURE fkgetcodmg

Return Iif(!IsEmpty(DORig.Cd_MG_P), DORig.Cd_MG_P, DORig.Cd_MG_A)

ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC

PROCEDURE contextmenuproc

Lparameters nCBMId, xPar1, lFromCode



** Questo codice viene richiamato la prima volta dal menu (con lFromCode == .F.); la chiamata da menu

** deve essere rigirata nel metodo centralizzato Grid_ContextMenuProc,  che poi provvede a richiamare

** questo metodo, stavolta con lFromCode == .T. in modo da evitare la ricorsione



If !lFromCode

	Return Thisform.CallerCntGrid.Grid_ContextMenuProc(This, .T., nCBMId, xPar1)

Else

	Return DoDefault(nCBMId, xPar1)

Endif





ENDPROC

PROCEDURE fkgetcodmgubicazione

Return Iif(!IsEmpty(DORig.Cd_MG_P), DORig.Cd_MGUbicazione_P, DORig.Cd_MGUbicazione_A)

ENDPROC

PROCEDURE fkgetautoinsertmode

Return Evaluate(Thisform.Parameters.ParentForm.PF.pgGenerale.txtCd_DO.Field.FKAlias + '.ARLottoAuto')

ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgGenerale.txtCd_DOSottoCommessa) ***
*** PROPERTIES ***
ControlSource = "DORig.Cd_DOSottoCommessa"

Format = "!"

Top = 11

Width = 92

fkselect = SELECT * FROM DOSottoCommessa WHERE Cd_DOSottoCommessa = <TEXT>

fktabledesc = Sottocommessa

fkdecodedfield = Descrizione

fkhasdisplay = .T.

fkacceptinvalid = .T.

Name = "Field"


*** METHODS ***
PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgGenerale.txtPrezzoUnitarioV) ***
*** PROPERTIES ***
Comment = "5AA1674E-07C5-4555-96B3-18BF1CCAB42E"

Alignment = 1

ControlSource = "DORig.PrezzoUnitarioV"

Top = 11

Width = 92

Name = "Field"


*** METHODS ***
PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE onvaluepick

LParameters nSearchFormType, xValue4Value, oSelectedRec, lFromCode



** Questo codice viene richiamato la prima volta dal menu (con lFromCode == .F.); la chiamata da menu

** deve essere rigirata nel metodo centralizzato Grid_OnValuePick, che poi provvede a richiamare

** questo metodo, stavolta con lFromCode == .T. in modo da evitare la ricorsione



If !lFromCode

	Return Thisform.CallerCntGrid.Grid_OnValuePick(This, .T., nSearchFormType, xValue4Value, oSelectedRec)

Else

	Return DoDefault(nSearchFormType, xValue4Value, oSelectedRec)

EndIf



ENDPROC

PROCEDURE KeyPress

LParameters nKeyCode, nShiftAltCtrl



If nKeyCode = -2 																&& F3 - Fast Search

	This.ContextMenuProc(CMM_PROCESS_CHOICE, MB_EDIT_SRCHSPEC0)	

	NoDefault

	Return .T.

EndIf



If (nKeyCode = 83 Or nKeyCode = 115) And nShiftAltCtrl = 0 	&& s - Scorporo

	This.ContextMenuProc(CMM_PROCESS_CHOICE, MB_EDIT_SRCHSPEC1)

	NoDefault

	Return .T.

EndIf



Return DoDefault(nKeyCode, nShiftAltCtrl)



ENDPROC

PROCEDURE contextmenuproc

Lparameters nCBMId, xPar1, lFromCode



** Questo codice viene richiamato la prima volta dal menu (con lFromCode == .F.); la chiamata da menu

** deve essere rigirata nel metodo centralizzato Grid_ContextMenuProc,  che poi provvede a richiamare

** questo metodo, stavolta con lFromCode == .T. in modo da evitare la ricorsione



If !lFromCode

	Return Thisform.CallerCntGrid.Grid_ContextMenuProc(This, .F., nCBMId, xPar1)

Else

	Return DoDefault(nCBMId, xPar1)

Endif





ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgGenerale.txtPrezzoTotaleV) ***
*** PROPERTIES ***
Comment = "878368D0-FDD1-45DD-BD16-71E67565B17C"

Alignment = 1

ControlSource = "DORig.PrezzoTotaleV"

Enabled = .F.

Top = 11

Width = 92

DisabledForeColor = 0,0,0

Name = "Field"


*** METHODS ***
PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC

PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgGenerale.txtScontoAddizionale) ***
*** PROPERTIES ***
Comment = "E20A10E6-894C-4D74-9E1C-FB1BA19B0AAC"

Alignment = 0

ControlSource = "DORig.ScontoAddizionale"

Top = 11

Width = 92

Name = "Field"


*** METHODS ***
PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgGenerale.txtPrezzoAddizionaleV) ***
*** PROPERTIES ***
Comment = "A640D4EC-1C13-4E98-80F8-A58C29A6167E"

Alignment = 1

ControlSource = "DORig.PrezzoAddizionaleV"

Top = 11

Width = 92

Name = "Field"


*** METHODS ***
PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgGenerale.txtScontoRiga) ***
*** PROPERTIES ***
Comment = "77D5CFC9-9346-44C0-8506-851D3424AB53"

ControlSource = "DORig.ScontoRiga"

Height = 19

Left = 0

Top = 11

Width = 92

Name = "Field"


*** METHODS ***
PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgGenerale.txtCd_Aliquota) ***
*** PROPERTIES ***
ControlSource = "DORig.Cd_Aliquota"

Format = "!"

Height = 19

Left = 0

Top = 11

Width = 28

fkselect = SELECT * FROM Aliquota WHERE Cd_Aliquota = <TEXT> And Ivasplit = 0

fktabledesc = Aliquote

fkdecodedfield = Descrizione

fkhasdisplay = .T.

Name = "Field"


*** METHODS ***
PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC

PROCEDURE fkselect_access

Return This.FKSelect + Iif(!Thisform.oCaller.IvaMoss_Set(), ' And Aliquota.IvaMoss = 0', '')



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgGenerale.txtCd_CGConto) ***
*** PROPERTIES ***
ControlSource = "DORig.Cd_CGConto"

Top = 11

Width = 92

Name = "Field"


*** METHODS ***
PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgGenerale.txtProvvigioneRiga_1) ***
*** PROPERTIES ***
Comment = "9D240781-66E3-4148-9986-B07A64BEDF9F"

ControlSource = "DORig.ProvvigioneRiga_1"

Top = 11

Width = 92

Name = "Field"


*** METHODS ***
PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgGenerale.txtProvvigioneRiga_2) ***
*** PROPERTIES ***
Comment = "18878172-EBB9-4F7F-99BA-ECC190A9D825"

ControlSource = "DORig.ProvvigioneRiga_2"

Top = 11

Width = 92

Name = "Field"


*** METHODS ***
PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgGenerale.txtDataConsegna) ***
*** PROPERTIES ***
Comment = "E4F7D494-B611-40F5-BDC6-CB31230A16D4"

Alignment = 3

Value = {}

ControlSource = "DORig.DataConsegna"

Top = 11

Width = 63

DisabledForeColor = 0,0,0

Name = "Field"


*** METHODS ***
PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgGenerale.txtPackList) ***
*** PROPERTIES ***
Comment = "49BA525B-9F31-4AC8-AFCB-3F03013730A6"

ControlSource = "DORig.PackListRef"

Top = 11

Width = 92

Name = "Field"


*** METHODS ***
PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC

PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgGenerale.txtTipoPC) ***
*** PROPERTIES ***
Comment = "4B31C7D1-0DEF-4672-82B2-A4B2C932A4E5"

ControlSource = "DORig.TipoPC"

Top = 11

Width = 16

Name = "Field"


*** METHODS ***
PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC

PROCEDURE contextmenuproc

Lparameters nCBMId, xPar1, lFromCode



** Questo codice viene richiamato la prima volta dal menu (con lFromCode == .F.); la chiamata da menu

** deve essere rigirata nel metodo centralizzato Grid_ContextMenuProc,  che poi provvede a richiamare

** questo metodo, stavolta con lFromCode == .T. in modo da evitare la ricorsione



If !lFromCode

	Return Thisform.CallerCntGrid.Grid_ContextMenuProc(This, .F., nCBMId, xPar1)

Else

	Return DoDefault(nCBMId, xPar1)

Endif





ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgGenerale.Cnt_RR.txtRR_DataInizio) ***
*** PROPERTIES ***
Comment = "9EA24403-ABC2-48F0-BA51-41419ED78522"

ControlSource = "DoRig.RR_DataInizio"

Top = 11

Width = 84

BorderColor = 128,128,128

Name = "Field"


*** METHODS ***
PROCEDURE tooltiptext_access

Return Iif(This.When(), DoDefault(), 'Campo non abilitato')

ENDPROC

PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf



Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)





ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgGenerale.Cnt_RR.txtRR_DataFine) ***
*** PROPERTIES ***
Comment = "79881768-59EB-40F2-9599-0DC32AAE3425"

ControlSource = "DoRig.RR_DataFine"

Top = 11

Width = 84

BorderColor = 128,128,128

Name = "Field"


*** METHODS ***
PROCEDURE tooltiptext_access

Return Iif(This.When(), DoDefault(), 'Campo non abilitato')

ENDPROC

PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf



Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)





ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgGenerale.Cnt_RR.txtRR_Cd_CGConto) ***
*** PROPERTIES ***
ControlSource = "DoRig.RR_Cd_CGConto"

Top = 11

Width = 90

fkhasdisplay = .T.

Name = "Field"


*** METHODS ***
PROCEDURE tooltiptext_access

Return Iif(This.When(), DoDefault(), 'Campo non abilitato')

ENDPROC

PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC

PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf



Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)





ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: combobox, Parent: detail.PF.pgGenerale.cmbOmaggio) ***
*** PROPERTIES ***
Comment = "B573D450-CD18-425E-9CF6-9502CF91EA0B"

BoundColumn = 2

ControlSource = "DoRig.Omaggio"

Top = 11

Width = 148

BoundTo = .T.

Name = "Field"


*** METHODS ***
PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC

PROCEDURE Init

Local cAlias, nWa



cAlias = GetUniqueName()

nWa = Select(0)

Create Cursor &cAlias (Col1 C(20), Col2 N(2,0))	

Insert Into &cAlias (Col1, Col2) Values ('Nessuno', 1)

Insert Into &cAlias (Col1, Col2) Values ('Imponibile', 2)

Insert Into &cAlias (Col1, Col2) Values ('Imponibile + Iva', 3)



This.DisplayCount	 		= 3

This.RowSourceType 		= 2

This.RowSource				= cAlias

This.RowSourceAutoClose = .T.			&& Garantisce chiusura di (cAlias) nel destroy



Select (nWa)



DoDefault()

ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgCOAN.txtDataRif) ***
*** PROPERTIES ***
Comment = "9223DC6A-363D-4573-B141-5A83C5B8C49A"

Enabled = .F.

Height = 19

Left = 0

SpecialEffect = 2

Top = 11

Width = 92

DisabledForeColor = 0,0,128

BorderColor = 128,128,128

Name = "Field"


*** METHODS ***
PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgCOAN.txtCd_CAFormula) ***
*** PROPERTIES ***
ControlSource = "DoRig.Cd_CAFormula"

Format = "!"

Top = 11

fkhasdisplay = .T.

Name = "Field"


*** METHODS ***
PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgCOAN.txtCd_CAVda) ***
*** PROPERTIES ***
ControlSource = "DoRig.Cd_CAVda"

Format = "!"

Top = 11

fkselect = SELECT * FROM CAVda WHERE Cd_CAVda = <TEXT>

fktabledesc = Voci di analisi

fkdecodedfield = Descrizione

fkhasdisplay = .T.

Name = "Field"


*** METHODS ***
PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgCOAN.TxtCAPartenza) ***
*** PROPERTIES ***
Comment = "4BD3C607-FB4F-4E01-AF02-E4A89E58DE2F"

Top = 11

Width = 110

Name = "Field"


*** METHODS ***
PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: combobox, Parent: detail.PF.pgCOAN.cmbCAPartenzaEdit) ***
*** PROPERTIES ***
Comment = "6FEE1B51-4FC5-4263-912E-7967B3F31ABB"

ControlSource = "DoRig.CAPartenza"

TabIndex = 6

Top = 11

Width = 110

Name = "Field"


*** METHODS ***
PROCEDURE When

Return Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgCOAN.txtCd_CACda) ***
*** PROPERTIES ***
ControlSource = "DoRig.Cd_CACda"

Format = "!"

Top = 11

fkselect = SELECT * FROM CACda WHERE Cd_CACda = <TEXT>

fktabledesc = Centri di analisi

fkdecodedfield = Descrizione

fkhasdisplay = .T.

Name = "Field"


*** METHODS ***
PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgFEPA.PFX.PgDati.TxtRiferimentoAmm) ***
*** PROPERTIES ***
Comment = "6FCEC904-17E8-4BFC-91A3-8CFB71DDF102"

Top = 11

Width = 200

Name = "Field"


*** METHODS ***
PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgFEPA.PFX.PgDati.txtDataInizio) ***
*** PROPERTIES ***
Comment = "E4F7D494-B611-40F5-BDC6-CB31230A16D4"

Alignment = 3

Value = {}

Top = 11

Width = 108

DisabledForeColor = 0,0,0

Name = "Field"


*** METHODS ***
PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: detail.PF.pgFEPA.PFX.PgDati.TxtDataFine) ***
*** PROPERTIES ***
Comment = "E4F7D494-B611-40F5-BDC6-CB31230A16D4"

Alignment = 3

Value = {}

Top = 11

Width = 108

DisabledForeColor = 0,0,0

Name = "Field"


*** METHODS ***
PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC

PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: pgpiede.cntDDT.txtTrasporto) ***
*** PROPERTIES ***
ControlSource = "dotes.cd_dotrasporto"

Format = "!"

Left = 62

TabIndex = 3

Top = 0

Width = 35

ZOrderSet = 1

fkselect = SELECT * FROM DOTrasporto WHERE Cd_DOTrasporto = <TEXT>

fktabledesc = Trasporto

fkdecodedfield = Descrizione

fkhasdisplay = .T.

Name = "Field"


*** METHODS ***
PROCEDURE fkshowdescription

LParameters cDescText



DoDefault(cDescText)

This.ToolTipText = RTrim(cDescText)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: pgpiede.cntDDT.txtVettore1) ***
*** PROPERTIES ***
ControlSource = "dotes.cd_dovettore_1"

Format = "!"

Left = 62

TabIndex = 8

Top = 0

Width = 35

ZOrderSet = 6

fkselect = SELECT * FROM DOVettore WHERE Cd_DOVettore = <TEXT>

fktabledesc = Vettore

fkdecodedfield = Descrizione

fkhasdisplay = .T.

Name = "Field"


*** METHODS ***
PROCEDURE fkshowdescription

LParameters cDescText



DoDefault(cDescText)

This.ToolTipText = RTrim(cDescText)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: pgpiede.cntDDT.txtVettore2) ***
*** PROPERTIES ***
ControlSource = "dotes.cd_dovettore_2"

Format = "!"

Left = 62

TabIndex = 11

Top = 0

Width = 35

ZOrderSet = 9

fkselect = SELECT * FROM DOVettore WHERE Cd_DOVettore = <TEXT>

fktabledesc = Vettore

fkdecodedfield = Descrizione

fkhasdisplay = .T.

Name = "Field"


*** METHODS ***
PROCEDURE fkshowdescription

LParameters cDescText



DoDefault(cDescText)

This.ToolTipText = RTrim(cDescText)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: pgpiede.cntDDT.txtSpedizione) ***
*** PROPERTIES ***
ControlSource = "dotes.cd_dosped"

Format = "!"

Left = 62

TabIndex = 17

Top = 0

Width = 35

ZOrderSet = 16

fkselect = SELECT * FROM DOSped WHERE Cd_DOSped = <TEXT>

fktabledesc = Spedizione

fkdecodedfield = Descrizione

fkhasdisplay = .T.

Name = "Field"


*** METHODS ***
PROCEDURE fkshowdescription

LParameters cDescText



DoDefault(cDescText)

This.ToolTipText = RTrim(cDescText)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: pgpiede.cntDDT.txtPorto) ***
*** PROPERTIES ***
ControlSource = "dotes.cd_doporto"

Format = "!"

Left = 62

TabIndex = 18

Top = 0

Width = 35

ZOrderSet = 17

fkselect = SELECT * FROM DOPorto WHERE Cd_DOPorto = <TEXT>

fktabledesc = Porto

fkdecodedfield = Descrizione

fkhasdisplay = .T.

Name = "Field"


*** METHODS ***
PROCEDURE fkshowdescription

LParameters cDescText



DoDefault(cDescText)

This.ToolTipText = RTrim(cDescText)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: pgpiede.cntDDT.txtAspettoBeni) ***
*** PROPERTIES ***
ControlSource = "dotes.cd_doaspbene"

Format = "!"

Left = 62

TabIndex = 19

Top = 0

Width = 35

ZOrderSet = 18

fkselect = SELECT * FROM DOAspBene WHERE Cd_DOAspBene = <TEXT>

fktabledesc = Aspetto Beni

fkdecodedfield = Descrizione

fkhasdisplay = .T.

Name = "Field"


*** METHODS ***
PROCEDURE fkshowdescription

LParameters cDescText



DoDefault(cDescText)

This.ToolTipText = RTrim(cDescText)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: pgpiede.cntDDT.txtPesoLordo) ***
*** PROPERTIES ***
Comment = "94C3A755-6B5A-4FC9-B41F-04997F9F638C"

Anchor = 8

Alignment = 1

ControlSource = "dotes.pesolordo"

Height = 19

InputMask = "#,###,###.###"

Left = 91

TabIndex = 25

Top = 0

Width = 79

ZOrderSet = 27

Name = "Field"


*** METHODS ***
PROCEDURE contextmenuproc

Lparameters nCBMId, xPar1



**	nCBMId == CMM_ADD_ITEMS_TO_CONTEXT_MENU	-> xPar1 oggetto oMenu di classe ShortcutMenu 	

**	nCBMId == CMM_ADD_ITEMS_TO_EDIT_PAD			-> xPar1 Edit Popup Name								

**	nCBMId == CMM_PROCESS_CHOICE					-> xPar1 choice id (numerico)							- RetVal .T. se choice id riconosciuta e processata, .f. in caso contrario



Do Case



	Case nCBMId == CMM_ADD_ITEMS_TO_CONTEXT_MENU			&& xPar1 oggetto oMenu di classe ShortcutMenu 



		Local oMenu

		

		DoDefault(nCBMId, xPar1, MB_EDIT_SRCFAST_NOBAR + MB_EDIT_SRCFULL_NOBAR + MB_EDIT_SRCFEDI_NOBAR)		

		

		oMenu = xPar1

		If This.Enabled And !This.ReadOnly 

			oMenu.AddMenuBar('\-',,,MB_EDIT_SEP_SEARCH)

			oMenu.AddMenuBar(Thisform.TM_(,"FBC6CD7F-D1FE-46DE-8D9C-747900818E39", "Calcola Peso \<Lordo totale"), ,'Key Alt+0, "s"',	MB_EDIT_SRCHSPEC0,,.F.,, "Images\Included\Sum.bmp")

		EndIf

		

		Return .T.



	Case nCBMId == CMM_ADD_ITEMS_TO_EDIT_PAD		&& xPar1 Edit Popup Name 

		

		Local cPopupName, cOnSelCmd, cForm

		

		DoDefault(nCBMId, xPar1) 	

		

		cPopupName = xPar1

		cForm		  = Thisform.Name

		If This.Enabled And !This.ReadOnly 

			DefineBar(MB_EDIT_SEP_SEARCH, cPopupName, [Prompt "\-"])

			DefineBar(MB_EDIT_SRCHSPEC0, cPopupName, [Prompt &cForm..TM_(,"0EEBC507-8FEC-47F4-B78A-67AC0F3F5A86", "Calcola Peso \<Lordo totale") Key Alt+0, "s" Picture "Images\Included\Sum.bmp"])



			cOnSelCmd =  Sys(1272, This) + '.ContextMenuProc(' + Transform(CMM_PROCESS_CHOICE) + ', Bar())'



			On Selection 	Bar (MB_EDIT_SRCHSPEC0 ) Of (cPopupName) &cOnSelCmd

		EndIf



		Return .T.

		

	Case nCBMId == CMM_PROCESS_CHOICE						&& xPar1 nChoiceId - Torna .T. nel caso nChoiceId sia stato processato



		Local nChoiceId, oSrchForm



		nChoiceId  = xPar1



		Do Case

			Case nChoiceId == MB_EDIT_SRCHSPEC0

				If This.Enabled And !This.ReadOnly 

					This.Parent.btnSommaPesoLordo.Click()

				EndIf 

				Return .T.

				

			Otherwise

				Return DoDefault(nCBMId, nChoiceId)

		EndCase

			



EndCase

ENDPROC

PROCEDURE KeyPress

LParameters nKeyCode, nShiftAltCtrl



If nKeyCode = 115 																&& s - Somma

	This.ContextMenuProc(CMM_PROCESS_CHOICE, MB_EDIT_SRCHSPEC0)	

	NoDefault

	Return .T.

EndIf



Return DoDefault(nKeyCode, nShiftAltCtrl)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: pgpiede.cntDDT.txtPesoNetto) ***
*** PROPERTIES ***
Comment = "4B44600E-A58B-4D6B-8C62-094269EFB8DC"

Anchor = 8

Alignment = 1

ControlSource = "dotes.pesonetto"

Height = 19

InputMask = "#,###,###.###"

Left = 91

TabIndex = 26

Top = 0

Width = 79

ZOrderSet = 26

Name = "Field"


*** METHODS ***
PROCEDURE contextmenuproc

Lparameters nCBMId, xPar1



**	nCBMId == CMM_ADD_ITEMS_TO_CONTEXT_MENU	-> xPar1 oggetto oMenu di classe ShortcutMenu 	

**	nCBMId == CMM_ADD_ITEMS_TO_EDIT_PAD			-> xPar1 Edit Popup Name								

**	nCBMId == CMM_PROCESS_CHOICE					-> xPar1 choice id (numerico)							- RetVal .T. se choice id riconosciuta e processata, .f. in caso contrario



Do Case



	Case nCBMId == CMM_ADD_ITEMS_TO_CONTEXT_MENU			&& xPar1 oggetto oMenu di classe ShortcutMenu 



		Local oMenu

		

		DoDefault(nCBMId, xPar1, MB_EDIT_SRCFAST_NOBAR + MB_EDIT_SRCFULL_NOBAR + MB_EDIT_SRCFEDI_NOBAR)		

		

		oMenu = xPar1

		If This.Enabled And !This.ReadOnly 

			oMenu.AddMenuBar('\-',,,MB_EDIT_SEP_SEARCH)

			oMenu.AddMenuBar(Thisform.TM_(,"EF996FF3-231D-41E6-9025-573AE60987FF", "Calcola Peso \<Netto totale"), ,'Key Alt+0, "s"',	MB_EDIT_SRCHSPEC0,,.F.,, "Images\Included\Sum.bmp")

		EndIf

		

		Return .T.



	Case nCBMId == CMM_ADD_ITEMS_TO_EDIT_PAD		&& xPar1 Edit Popup Name 

		

		Local cPopupName, cOnSelCmd, cForm

		

		DoDefault(nCBMId, xPar1) 	

		

		cPopupName = xPar1

		cForm		  = Thisform.Name

		If This.Enabled And !This.ReadOnly 

			DefineBar(MB_EDIT_SEP_SEARCH, cPopupName, [Prompt "\-"])

			DefineBar(MB_EDIT_SRCHSPEC0, cPopupName, [Prompt &cForm..TM_(,"4B9AFB7A-B57E-4DD5-AED9-1799425FA3AA", "Calcola Peso \<Netto totale") Key Alt+0, "s" Picture "Images\Included\Sum.bmp"])



			cOnSelCmd =  Sys(1272, This) + '.ContextMenuProc(' + Transform(CMM_PROCESS_CHOICE) + ', Bar())'



			On Selection 	Bar (MB_EDIT_SRCHSPEC0 ) Of (cPopupName) &cOnSelCmd

		EndIf



		Return .T.

		

	Case nCBMId == CMM_PROCESS_CHOICE						&& xPar1 nChoiceId - Torna .T. nel caso nChoiceId sia stato processato



		Local nChoiceId, oSrchForm



		nChoiceId  = xPar1



		Do Case

			Case nChoiceId == MB_EDIT_SRCHSPEC0

				If This.Enabled And !This.ReadOnly 

					This.Parent.btnSommaPesoNetto.Click()

				EndIf 

				Return .T.

				

			Otherwise

				Return DoDefault(nCBMId, nChoiceId)

		EndCase

			



EndCase

ENDPROC

PROCEDURE KeyPress

LParameters nKeyCode, nShiftAltCtrl



If nKeyCode = 115 																&& s - Somma

	This.ContextMenuProc(CMM_PROCESS_CHOICE, MB_EDIT_SRCHSPEC0)	

	NoDefault

	Return .T.

EndIf



Return DoDefault(nKeyCode, nShiftAltCtrl)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: pgpiede.cntDDT.txtVolume) ***
*** PROPERTIES ***
Comment = "10AB2FB2-4E44-434E-91CA-1A54BB3EEE6F"

Anchor = 8

Alignment = 1

ControlSource = "dotes.volumeTotale"

Height = 19

InputMask = "#,###,###.###"

Left = 83

TabIndex = 29

Top = 0

Width = 79

ZOrderSet = 23

Name = "Field"


*** METHODS ***
PROCEDURE contextmenuproc

Lparameters nCBMId, xPar1



**	nCBMId == CMM_ADD_ITEMS_TO_CONTEXT_MENU	-> xPar1 oggetto oMenu di classe ShortcutMenu 	

**	nCBMId == CMM_ADD_ITEMS_TO_EDIT_PAD			-> xPar1 Edit Popup Name								

**	nCBMId == CMM_PROCESS_CHOICE					-> xPar1 choice id (numerico)							- RetVal .T. se choice id riconosciuta e processata, .f. in caso contrario



Do Case



	Case nCBMId == CMM_ADD_ITEMS_TO_CONTEXT_MENU			&& xPar1 oggetto oMenu di classe ShortcutMenu 



		Local oMenu

		

		DoDefault(nCBMId, xPar1, MB_EDIT_SRCFAST_NOBAR + MB_EDIT_SRCFULL_NOBAR + MB_EDIT_SRCFEDI_NOBAR)		

		

		oMenu = xPar1

		If This.Enabled And !This.ReadOnly 

			oMenu.AddMenuBar('\-',,,MB_EDIT_SEP_SEARCH)

			oMenu.AddMenuBar(Thisform.TM_(,"E38647EB-0150-4E82-9300-4484E8209B09", "Calcola \<Volume totale"), ,'Key Alt+0, "s"',	MB_EDIT_SRCHSPEC0,,.F.,, "Images\Included\Sum.bmp")

		EndIf

		

		Return .T.



	Case nCBMId == CMM_ADD_ITEMS_TO_EDIT_PAD		&& xPar1 Edit Popup Name 

		

		Local cPopupName, cOnSelCmd, cForm

		

		DoDefault(nCBMId, xPar1) 	

		

		cPopupName = xPar1

		cForm		  = Thisform.Name

		If This.Enabled And !This.ReadOnly 

			DefineBar(MB_EDIT_SEP_SEARCH, cPopupName, [Prompt "\-"])

			DefineBar(MB_EDIT_SRCHSPEC0 , cPopupName, [Prompt &cForm..TM_(,"36738BC7-587B-4830-958C-289C74662442", "Calcola \<Volume totale") Key Alt+0, "s" Picture "Images\Included\Sum.bmp"])



			cOnSelCmd =  Sys(1272, This) + '.ContextMenuProc(' + Transform(CMM_PROCESS_CHOICE) + ', Bar())'



			On Selection 	Bar (MB_EDIT_SRCHSPEC0 ) Of (cPopupName) &cOnSelCmd

		EndIf



		Return .T.

		

	Case nCBMId == CMM_PROCESS_CHOICE						&& xPar1 nChoiceId - Torna .T. nel caso nChoiceId sia stato processato



		Local nChoiceId, oSrchForm



		nChoiceId  = xPar1



		Do Case

			Case nChoiceId == MB_EDIT_SRCHSPEC0

				If This.Enabled And !This.ReadOnly 

					This.Parent.btnSommaVolume.Click()

				EndIf 

				Return .T.

				

			Otherwise

				Return DoDefault(nCBMId, nChoiceId)

		EndCase

			



EndCase

ENDPROC

PROCEDURE KeyPress

LParameters nKeyCode, nShiftAltCtrl



If nKeyCode = 115 																&& s - Somma

	This.ContextMenuProc(CMM_PROCESS_CHOICE, MB_EDIT_SRCHSPEC0)	

	NoDefault

	Return .T.

EndIf



Return DoDefault(nKeyCode, nShiftAltCtrl)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: pgpiede.cntDDT.txtColli) ***
*** PROPERTIES ***
Comment = "FA41100F-CF4B-42BB-8B88-8C384934AF09"

Anchor = 8

Alignment = 1

ControlSource = "dotes.colli"

Height = 19

Left = 31

TabIndex = 30

Top = 0

Width = 79

ZOrderSet = 22

Name = "Field"


*** METHODS ***
PROCEDURE contextmenuproc

Lparameters nCBMId, xPar1



**	nCBMId == CMM_ADD_ITEMS_TO_CONTEXT_MENU	-> xPar1 oggetto oMenu di classe ShortcutMenu 	

**	nCBMId == CMM_ADD_ITEMS_TO_EDIT_PAD			-> xPar1 Edit Popup Name								

**	nCBMId == CMM_PROCESS_CHOICE					-> xPar1 choice id (numerico)							- RetVal .T. se choice id riconosciuta e processata, .f. in caso contrario



Do Case



	Case nCBMId == CMM_ADD_ITEMS_TO_CONTEXT_MENU			&& xPar1 oggetto oMenu di classe ShortcutMenu 



		Local oMenu

		

		DoDefault(nCBMId, xPar1, MB_EDIT_SRCFAST_NOBAR + MB_EDIT_SRCFULL_NOBAR + MB_EDIT_SRCFEDI_NOBAR)		

		

		oMenu = xPar1

		If This.Enabled And !This.ReadOnly And This.Parent.btnSommaColli.Visible

			oMenu.AddMenuBar('\-',,,MB_EDIT_SEP_SEARCH)

			oMenu.AddMenuBar(Thisform.TM_(,"808A89FA-A3E3-4CD1-87DE-1756B49AE421", "Calcola numero \<Colli totale"), ,'Key Alt+0, "s"',	MB_EDIT_SRCHSPEC0,,.F.,, "Images\Included\Sum.bmp")

		EndIf

		

		Return .T.



	Case nCBMId == CMM_ADD_ITEMS_TO_EDIT_PAD		&& xPar1 Edit Popup Name 

		

		Local cPopupName, cOnSelCmd, cForm

		

		DoDefault(nCBMId, xPar1) 	

		

		cPopupName = xPar1

		cForm		  = Thisform.Name

		If This.Enabled And !This.ReadOnly And This.Parent.btnSommaColli.Visible

			DefineBar(MB_EDIT_SEP_SEARCH, cPopupName, [Prompt "\-"])

			DefineBar(MB_EDIT_SRCHSPEC0, cPopupName, [Prompt &cForm..TM_(,"C62D8CCA-3249-42F8-B817-1D26C6986330", "Calcola numero \<Colli totale") Key Alt+0, "s" Picture "Images\Included\Sum.bmp"])



			cOnSelCmd =  Sys(1272, This) + '.ContextMenuProc(' + Transform(CMM_PROCESS_CHOICE) + ', Bar())'



			On Selection 	Bar (MB_EDIT_SRCHSPEC0 ) Of (cPopupName) &cOnSelCmd

		EndIf



		Return .T.

		

	Case nCBMId == CMM_PROCESS_CHOICE						&& xPar1 nChoiceId - Torna .T. nel caso nChoiceId sia stato processato



		Local nChoiceId, oSrchForm



		nChoiceId  = xPar1



		Do Case

			Case nChoiceId == MB_EDIT_SRCHSPEC0

				If This.Enabled And !This.ReadOnly And This.Parent.btnSommaColli.Visible 

					This.Parent.btnSommaColli.Click()

				EndIf 

				Return .T.

				

			Otherwise

				Return DoDefault(nCBMId, nChoiceId)

		EndCase

			



EndCase

ENDPROC

PROCEDURE KeyPress

LParameters nKeyCode, nShiftAltCtrl



If nKeyCode = 115 																&& s - Somma

	This.ContextMenuProc(CMM_PROCESS_CHOICE, MB_EDIT_SRCHSPEC0)	

	NoDefault

	Return .T.

EndIf



Return DoDefault(nKeyCode, nShiftAltCtrl)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: pgpiede.CntFattura.txtAcconto) ***
*** PROPERTIES ***
Comment = "1B0E246F-C1A8-4EC3-B74A-E62D39296B5B"

Alignment = 1

ControlSource = "dotes.AccontoPerc"

InputMask = "###.##"

Left = 60

Width = 50

Name = "Field"


*** METHODS ***
PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If lIsChanged

	If This.Value < 0

		xMessageBox(Thisform.TB_(,'ABDC0E83-A499-4371-8F17-75A738233496', "L'acconto percentuale non può essere negativo."), MB_ICONSTOP)

		Return 0

	Endif 

	

**		** DOCIVATI: acconti in perc 0% o 100%

**		If DoTes.ImportiIvati And This.Value != 0 And This.Value != 100

**			xMessageBox(Thisform.TB_(,'31B26447-4970-4E82-8559-2C669BD3E093', "Per i documenti che gestiscono Importi Ivati l'acconto percentuale deve essere zero o 100%."), MB_ICONSTOP)

**			Return 0

**		EndIf 

	

Endif 



Return Dodefault(lIsChanged, xOldValue)





ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: fedi.PF.pgGenerale.PF.pgGenerale.txtCF_Fatt) ***
*** PROPERTIES ***
ControlSource = "DoTes.Cd_CF_Fatt"

Height = 19

Left = 2

Top = 21

Width = 55

fktabledesc = Anagrafica

fkhasdisplay = .T.

checkfor = 1

Name = "Field"


*** METHODS ***
PROCEDURE onvaluechange

LParameters xOldValue



Thisform.SetRegimeIva('CF', xOldValue)

Thisform.SetRegimeIva('USERINTERFACE')

Thisform.DoIntento_Clear()

ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: fedi.PF.pgGenerale.PF.pgGenerale.cntPagamento.txtCd_PG) ***
*** PROPERTIES ***
ControlSource = "dotes.cd_pg"

Format = "!"

Left = 86

Top = 0

Width = 40

fkselect = SELECT * FROM PG WHERE Cd_PG = <TEXT>

fktabledesc = Pagamenti

fkdecodedfield = Descrizione

fkhasdisplay = .T.

Name = "Field"


*** METHODS ***
PROCEDURE onvaluechange

Lparameters xOldValue



Local cAlias



cAlias = This.FKAlias

	

RefreshField(This)



If !IsEmpty(This.Value) AND ;	

	(ThisForm.Mode = FEDIMODE_EDIT OR BitAnd(ThisForm.Mode, FEDIMODE_INS) != 0) AND;

	((BitAnd(ThisForm.Mode, FEDIMODE_INS) != 0 AND IsEmpty(xOldValue)) OR ;

	xMessageBox(Thisform.TB_(,"A567301F-DC79-4F2F-AC70-38233A25356D", 'Riproporre i default del pagamento %1! ?', This.Value), 4 + 32) == 6)

	

	ThisForm.EvalScontoCassa()

	

	** Ricalcolo le spese

	Iif(!ThisForm.PF.pgGenerale.txtCd_CF.Field.IsEmpty(), ThisForm.CalcSpese(0x01), .T.)



	With ThisForm.PF.pgGenerale.PF.pgPiede.Cnt.CntFattura

		.txtAcconto.Field.SetValue(&cAlias..AccontoPerc)

		.txtAcconto.Field1.SetValue(Round(&cAlias..AccontoFissoE * DoTes.Cambio, DoTes.Decimali))

	EndWith



	With ThisForm.PF.pgGenerale.PF.pgGenerale.cntDatiContabili

		If .txtCd_CGConto_BnSc.Field.IsEmpty() And .txtCd_CGConto_BnSc.Visible

			.txtCd_CGConto_BnSc.Field.SetValue(&cAlias..Cd_CGConto_banca)

		EndIf

	EndWith



EndIf



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: fedi.PF.pgGenerale.PF.pgGenerale.cntPagamento.txtCd_Agente) ***
*** PROPERTIES ***
ControlSource = "dotes.cd_agente_1"

Format = "!"

Height = 19

Left = 86

MaxLength = 3

TabIndex = 2

Top = 0

Width = 40

fkselect = SELECT * FROM Agente WHERE Cd_Agente = <TEXT>

fktabledesc = Agenti

fkdecodedfield = Descrizione

fkhasdisplay = .T.

Name = "Field"


*** METHODS ***
PROCEDURE onvaluechange

LPARAMETERS xOldValue



THISFORM.EvalScontoCassa()



ENDPROC

PROCEDURE fkshowdescription

LParameters cDescText



This.ToolTipText = RTrim(cDescText)



With This.Parent 

	.Display.Caption     = Nvl(                            .Field.ToolTipText + ' / ', '') +                                  .Field1.ToolTipText

	.Label.ToolTipText   = Nvl(.Field.Value + ' - ', '') + .Field.ToolTipText + CRLF       + Nvl(.Field1.Value + ' - ', '') + .Field1.ToolTipText

	.Display.ToolTipText = Nvl(.Field.Value + ' - ', '') + .Field.ToolTipText + CRLF       + Nvl(.Field1.Value + ' - ', '') + .Field1.ToolTipText

EndWith



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: fedi.PF.pgGenerale.PF.pgGenerale.cntPagamento.txtScontoCassa) ***
*** PROPERTIES ***
Comment = "56704411-A12B-4226-91CD-FE6653D36753"

ControlSource = "dotes.scontocassa"

Height = 19

Left = 86

ToolTipText = "Sconto cassa - genererà  giroconto"

Top = 0

Width = 82

Name = "Field"


*** METHODS ***
PROCEDURE onvaluechange

LPARAMETERS xOldValue



WITH THIS

	.Value = PercStrNormalize(.Value)

	RETURN DODEFAULT()

ENDWITH

ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: fedi.PF.pgGenerale.PF.pgGenerale.cntPagamento.txtDataPag) ***
*** PROPERTIES ***
Comment = "122E80AC-A9E5-4EB4-A569-F3E26F0106CB"

ControlSource = "DOTes.DataPag"

Height = 19

Left = 18

TabIndex = 2

Top = 0

Width = 66

Name = "Field"


*** METHODS ***
PROCEDURE contextmenuproc

Lparameters nCBMId, xPar1, xPar2



Return DoDefault(nCBMId, xPar1, xPar2)



**	Do Case



**		Case nCBMId == CMM_ADD_ITEMS_TO_CONTEXT_MENU			&& xPar1 oggetto oMenu di classe ShortcutMenu



**			Local oMenu, cForm

**			

**			DoDefault(nCBMId, xPar1, xPar2) 	&& La classe base aggiunge le voci per la clipboard, le date ed i filtri... 

**			

**			oMenu = xPar1

**			cForm = Thisform.Name

**			

**			If This.Enabled And !This.ReadOnly And Thisform.GetDataPag(.T.)

**				oMenu.AddMenuBar('\-',,,MB_EDIT_SEP_SEARCH)

**				oMenu.AddMenuBar(&cForm..TM_(,"01943490-53BF-451C-B129-D258DED71758", "Calcola data pagamento"),, 'Key Alt+0, "p"', MB_EDIT_SRCHSPEC0,,.F.,, )

**			EndIf



**			Return .T.



**		Case nCBMId == CMM_ADD_ITEMS_TO_EDIT_PAD		&& xPar1 Edit Popup Name

**			

**			Local cPopupName, cOnSelCmd, cKey, cForm

**			

**			DoDefault(nCBMId, xPar1, xPar2) 	&& La classe base aggiunge le voci per la clipboard, le date ed i filtri... 

**			

**			cPopupName = xPar1

**			cForm		  = Thisform.Name



**			If This.Enabled And !This.ReadOnly And Thisform.GetDataPag(.T.)



**				DefineBar(MB_EDIT_SEP_SEARCH, cPopupName, [Prompt "\-"])

**				DefineBar(MB_EDIT_SRCHSPEC0,  cPopupName, [Prompt &cForm..TM_(,"49BC1E54-5FCE-4B3B-94BA-BCC9509A4567", "Calcola data pagamento") Key Alt+0, "p"])



**				cOnSelCmd =  Sys(1272, This) + '.ContextMenuProc(' + Transform(CMM_PROCESS_CHOICE) + ', Bar())'

**				On Selection 	Bar (MB_EDIT_SRCHSPEC0) Of (cPopupName) &cOnSelCmd



**			EndIf

**			Return .T.

**			

**		Case nCBMId == CMM_PROCESS_CHOICE						&& xPar1 nChoiceId - Torna .T. nel caso nChoiceId sia stato processato



**			Do Case

**				Case xPar1 == MB_EDIT_SRCHSPEC0

**					If This.Enabled And !This.ReadOnly And Thisform.GetDataPag(.T.)

**						This.SetValue(Thisform.GetDataPag())

**					EndIf 

**					Return .T.

**					

**				Otherwise

**					Return DoDefault(nCBMId, xPar1, xPar2)

**			EndCase

**				



**	EndCase

ENDPROC

PROCEDURE KeyPress

LParameters nKeyCode, nShiftAltCtrl



**	If (nKeyCode = 80 Or nKeyCode = 112) And nShiftAltCtrl = 0 	&& p/P - proponi data con giorni del pagamento

**		This.ContextMenuProc(CMM_PROCESS_CHOICE, MB_EDIT_SRCHSPEC0)

**		NoDefault

**		Return .T.

**	EndIf



Return DoDefault(nKeyCode, nShiftAltCtrl)

ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: fedi.PF.pgGenerale.PF.pgGenerale.cntVarie.txtDataConsegna) ***
*** PROPERTIES ***
Comment = "C8163AE6-7279-4DE8-969E-BCBD13E43E4A"

ControlSource = "DoTes.DataConsegna"

Left = 80

ToolTipText = "Data consegna globale - inibisce data consegna per riga"

Top = 0

Width = 63

Name = "Field"


*** METHODS ***
PROCEDURE onvaluechange

Lparameters xOldValue



Local nOldWA, nRec, nCount



Thisform.CopiaDataConsegna = .F.



If !IsEmpty(This.Value)



	** Se imposto una nuova data (da valore vuoto a 10-01-20xx), prima controllo che non ci siano righe con data consegna già impostata

	

	If IsEmpty(xOldValue)



		nOldWA = Select()



		Select DoRig

		nRec = Recno()

		Count To nCount For !IsEmpty(DoRig.DataConsegna) And DoRig.DataConsegna != This.Value 

		Locate Record (nRec)

		

		Select (nOldWA)

		

		If nCount > 0 And xMessageBox(TB_(, "75F22645-48B8-4A5E-9A34-484DF534CF14", 'Esistono delle righe con data di consegna già indicata.' + CRLF + 'Tali valori saranno modificati in %1!.' + CRLF + CRLF + 'Confermi la modifica delle date di consegna delle righe documento?', Dtoc(This.Value)), 4+32) = 7 && IDNO

			This.Value = {}

			Return 

		EndIf 		

	EndIf 





	Thisform.CopiaDataConsegna = .T.



	** Sovrascrivo le righe doc



	nOldWA = Select()



	Select DoRig

	nRec = Recno()

	Replace DataConsegna With This.Value For Nvl(DataConsegna, {}) != This.Value And IsEmpty(TipoRigaRif)

	Locate Record (nRec)



	Select (nOldWA)

Endif

ENDPROC

PROCEDURE isvalid

LPARAMETERS lIsChanged, xOldValue

IF !IsEmpty(THIS.VALUE)

	IF THIS.Value < DoTes.DataDoc

		xMessageBox(Thisform.TB_(,"22D68DA1-C8E5-4161-A231-12A8291B4A78", 'La data consegna non può essere inferiore alla data del documento.'), 16)

		RETURN .F.

	ENDIF

ENDIF



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: fedi.PF.pgGenerale.PF.pgGenerale.cntVarie.txtCd_Commessa) ***
*** PROPERTIES ***
ControlSource = "dotes.Cd_DoSottoCommessa"

Format = "!"

Left = 80

Top = 0

fkselect = SELECT * FROM DOSottocommessa WHERE Cd_DOSottoCommessa = <TEXT>

fktabledesc = Sottocommessa

fkdecodedfield = Descrizione

Name = "Field"


*** METHODS ***
PROCEDURE onvaluechange

LParameters xOldValue



Local oWA_R, nCount_R, oWA_S, nCount_S



If This.IsEmpty()

	Return 

EndIf 



** ----------- Controllo congruenza commesse sezione merce e spese



oWA_R = SelectWA('DoRig')

Calculate Cnt() For 	!Empty(Nvl(Cd_DOSottoCommessa, '')) And ;

							!(Rtrim(Nvl(Cd_DOSottoCommessa, '')) == Rtrim(Nvl(This.Value, ''))) And ;

							Empty(TipoRigaRif) ;

		To nCount_R In DoRig



oWA_S = SelectWA('DoRigSpesa')

Calculate Cnt() For 	!Empty(Nvl(Cd_SottoCommessa,  '')) And ;

							!(Rtrim(Nvl(Cd_SottoCommessa, '')) == Rtrim(Nvl(This.Value, ''))) ;

		To nCount_S In DoRigSpesa



If (nCount_R + nCount_S) = 0 Or ((nCount_R + nCount_S) > 0 And xMessageBox(Thisform.TB_(,'8B141664-59DE-4BBC-A83D-579FA2C0A2EB', "Nelle righe merce o spesa sono presenti delle sottocommesse diverse da quella specificata nella testata. Esse saranno sovrascritte." + CRLF + "Confermi l'operazione?"), 4 + 32) = IDYES)

	Replace Cd_DOSottoCommessa With This.Value For !(Rtrim(Nvl(Cd_DOSottoCommessa, '')) == Rtrim(Nvl(This.Value, ''))) And Empty(TipoRigaRif) In DoRig

	Replace Cd_SottoCommessa   With This.Value For !(Rtrim(Nvl(Cd_SottoCommessa, ''))   == Rtrim(Nvl(This.Value, ''))) 								In DoRigSpesa

Else

	This.Value = xOldValue

	This.OnRefresh()

EndIf



Release oWA_R

Release oWA_S



** ---------------------------------------------------------------



**	LParameters xOldValue



**	Local nOldRec, nOldWA, nConta

**	Local lOk



**	If IsEmpty(This.Value)

**		Return 

**	EndIf 



**	nOldWA = Select(0)



**	**



**	Select DoRig

**	nOldRec	= Iif(Eof(), 0, Recno())



**	** Conto se ci sono righe con Commessa diversa da quella appena impostata nella testa

**	Count To nConta For Empty(TipoRigaRif) And !IsEmpty(DoRig.Cd_DoSottoCommessa) And Rtrim(DoRig.Cd_DoSottoCommessa) != Rtrim(This.Value)



**	If nConta = 0

**		lOk = .T.

**	Else

**		If xMessageBox(Thisform.TB_(,'8B141664-59DE-4BBC-A83D-579FA2C0A2EB', "Nelle righe sono presenti delle commesse diverse da quella specificata nella testata. Esse saranno sovrascritte." + CRLF + "Confermi l'operazione?"), 4+32) = IDYES

**			lOk = .T.

**		Else

**			This.Value = xOldValue

**			lOk = .F.

**		EndIf 

**	EndIf 



**	If lOk

**		** Modifico le righe con Commessa diversa da quella impostata in testa

**		Replace All Cd_DoSottoCommessa With This.Value For Empty(TipoRigaRif) And Rtrim(Nvl(DoRig.Cd_DoSottoCommessa, '')) != Rtrim(Nvl(This.Value, '')) In DoRig

**	EndIf  



**	** Mi riposizione sulla WA e record 

**	If nOldRec > 0

**		Go (nOldRec)

**	EndIf 



**	** Mi riposizione sulla WA 

**	Select (nOldWA)

ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: fedi.PF.pgGenerale.PF.pgGenerale.txtNumeroDataRif) ***
*** PROPERTIES ***
Comment = "D3D93FBB-6FCF-4F5C-888E-EA6EC86ACD32"

ControlSource = "dotes.numerodocrif"

Height = 19

Left = 85

TabIndex = 3

ToolTipText = "Numero documento di riferimento"

Top = 21

Width = 150

Name = "Field"


*** METHODS ***
PROCEDURE tooltiptext_access

Local cText



cText = Thisform.CheckNumDocRif()

Return Evl(cText, DoDefault())



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: fedi.PF.pgGenerale.PF.pgGenerale.txtCd_LS) ***
*** PROPERTIES ***
ControlSource = "dotes.cd_ls_1"

Format = "!"

Left = 2

TabIndex = 3

ToolTipText = "Listino Primario/Particolare"

Top = 21

Width = 55

fkselect = SELECT * FROM LS WHERE Cd_LS = <TEXT>

fktabledesc = Listini

fkdecodedfield = Descrizione

fkhasdisplay = .T.

fkshowult_pv_ca = 3

Name = "Field"


*** METHODS ***
PROCEDURE onvaluechange

LParameters xOldValue



If InList(This.Value, LS_UVEN_C, LS_UVEN, LS_UACQ_F, LS_UACQ)

	Replace Cd_LS_2 With Null In DoTes

	This.Parent.Field1  .Visible = .F.

	This.Parent.Display1.Visible = .F.

	This.Parent.Display1.Caption = ''

Else

	This.Parent.Field1  .Visible = .T.

	This.Parent.Display1.Visible = .T.

EndIf 

ENDPROC

PROCEDURE fkshowdescription

Lparameters cDescText



DoDefault(cDescText)



This.ToolTipText = 'Listino Primario/Particolare' + Iif(IsEmpty(cDescText), '', ' - ' + Rtrim(cDescText))

ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



Local xRet

xRet = DoDefault(lIsChanged, xOldValue)

If Empty(xRet)

	Return xRet

EndIf



** Controllo se la valuta associata ha un fixing

If !IsEmpty(This.Value) And xSqlExec2Var(Textmerge('Select ExitCode From GetFixing(<<FormatC4Spt(This.FkRecord.Cd_VL)>>, <<FormatD4Spt(DoTes.DataDoc)>>)')) < 0

	xMessageBox(Thisform.TB_(,"1F25D44A-AFAC-4F1D-9DC9-F48B36118468", 'La valuta associata al listino %1! non ha alcun fixing. Non è possibile utilizzare tale listino.', This.Value), 48)

	This.FkShowDescription('')

	Return .F.

EndIf 



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: fedi.PF.pgGenerale.PF.pgGenerale.cntDatiContabili.TxtIban) ***
*** PROPERTIES ***
Comment = "E004FE71-5343-4114-802C-72E74149F3E1"

ControlSource = "Dotes.Iban"

Height = 19

Left = 83

Top = 0

activatecheck = .F.

Name = "Field"


*** METHODS ***
PROCEDURE onvaluechange

LParameters xOldValue



DoDefault(xOldValue)



If This.IsItalian()

	This.Parent.Parent.txtBic.Field.Setvalue(This.Get_BicCode())

EndIf



This.Parent.Parent.txtBic.Field.ReadOnly = This.IsItalian()

ENDPROC

PROCEDURE cmgetcf

Return DoTes.Cd_CF



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: fedi.PF.pgGenerale.PF.pgGenerale.cntDatiContabili.txtBic) ***
*** PROPERTIES ***
ControlSource = "DOTes.BicCode"

Left = 20

Top = 10

Name = "Field"


*** METHODS ***
PROCEDURE cmgetcf

Return DoTes.Cd_CF



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: fedi.PF.pgGenerale.PF.pgGenerale.cntDatiContabili.txtCd_ReverseCharge) ***
*** PROPERTIES ***
ControlSource = "DOTes.CD_ReverseCharge"

Format = "!"

Left = 82

Top = 0

Width = 37

fkselect = SELECT * FROM ReverseCharge WHERE Cd_ReverseCharge = <TEXT>

fktabledesc = Tipologie Reverse Charge

fkdecodedfield = Descrizione

fkhasdisplay = .T.

Name = "Field"


*** METHODS ***
PROCEDURE isvalid

LPARAMETERS lischanged, xoldvalue



Local xRet



xRet = Dodefault(lischanged, xoldvalue)



If !Empty(xRet) And lIsChanged And !This.lSkipMessage And ;

	DoTes.IvaSospesa And DoTes.Clifor = 'F' And DoTes.TipoFattura != 0 And ;

	xMessageBox(Thisform.TB_(,'C499997F-6D24-4AD0-A9C1-563F2E86386D', "L'operazione selezionata non prevede la gestione dell'iva per cassa. L'attributo verrà reimpostato." + Chr(13) + "Procedo?"), MB_YESNO + MB_ICONQUESTION + MB_DEFBUTTON2) = IDNO

	This.Value = xoldvalue

	xRet = 0

EndIf



Return xRet







ENDPROC

PROCEDURE onvaluechange

LPARAMETERS xOldValue



Local cAlias

cAlias = This.FKAlias



DoDefault(xOldValue)



** UE è un campo calcolato nel db ma lo gestisco per compatibilità anche in UI

Replace ;

	TipoFattura With &cAlias..TipoFattura ;

	Ue 			With (&cAlias..TipoFattura = 1) ;

	In DoTes



** Iva per cassa non è tecnicamente gestibile con il reverse charge e nemmeno interessata dalla normativa per cui resetto il campo. Avviso anche in querysave()

Thisform.SetRegimeIva('TIPOFATTURA', xOldValue)





ENDPROC

PROCEDURE Init

This.AddProperty('lSkipMessage', .T.)

Return DoDefault()

ENDPROC

PROCEDURE fktabledesc_access

Local cTableDesc



cTableDesc = ICase(Dotes.Clifor == 'F', TX_(, "CD289BF3-B611-405F-9387-6D9C6F917053", 'Causali Reverse Charge'), TX_(, "060B5542-16AA-4C09-8A1C-0E72534D84E1", 'Tipo Fattura'))



Return cTableDesc



ENDPROC

PROCEDURE fkselect_access

Local cFKSelect



cFKSelect = "SELECT * FROM ReverseCharge WHERE Cd_ReverseCharge = <TEXT>" + ;

				ICase(DoTes.Clifor == 'C', ' And TipoFattura  = 1', ;

						DoTes.Clifor == 'F', ' And TipoFattura >= 1', ;

						' And 1 = 0')



Return cFKSelect



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: fedi.PF.pgGenerale.txtCd_DO) ***
*** PROPERTIES ***
ControlSource = "dotes.cd_do"

Left = 0

Top = 11

ZOrderSet = 3

required = .T.

Name = "Field"


*** METHODS ***
PROCEDURE fkselect_access



Local cFKSelectWhere, cWhereParcella 



cFKSelectWhere = This.FKSelectWhere



If This.DoBitMask != TD_TUTTO

	cFKSelectWhere =  cFKSelectWhere + ;

							Iif(Empty(cFKSelectWhere), '', ' And ') + ;

							'(dbo.afn_DoTypeAsMask(Do.TipoDocumento, Do.CliFor) & ' + ToHex(This.DoBitMask) + ' != 0)'

EndIf





Return 'Select * From Do Where Do.Cd_Do = <TEXT> And Do.Cd_ParcT Is Null ' + Iif(Empty(cFKSelectWhere), '', ' And ' + cFKSelectWhere) + ;

			oApp.oUser.GetDOWhere('Do.Cd_Do') && Ho aggiungo il filtro per escludere le Parcelle



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



Local xRet



If !DoDefault(lIsChanged, xOldValue)

	Return .F.

EndIf



** Verifica condizione per documenti integrativi

xRet = Thisform.AutoTD_Chk('DO')

If Empty(xRet)

	Return xRet

EndIf



If lIsChanged And !IsEmpty(This.Value) And RecCount(This.fkAlias) > 0

	This.Enabled = .F.

Endif



ENDPROC

PROCEDURE onrefresh

LParameters xOldValue



DoDefault(xOldValue)



Local cDOAlias, oCauInfo, cStmt

Local nDoBitMask



Text To cStmt Textmerge NoShow Pretext 7

	Select Top 1

		Do.Cd_MGCausale,

		Do.Contabile,

		MGCausale.Cd_MG_A,

		MGCausale.Cd_MG_P,

		MGCausale.MagAFlag,

		MGCausale.MagPFlag,

		MGCausale.UIMagAFix,

		MGCausale.UIMagPFix,

		DoDoPrel.Id_DoDoPrel,

		Convert(Bit, Case When (PCCarQs != 0 Or PCScaQs != 0 Or ACCarQs != 0 Or ACScaQs != 0)

						      Then 1 Else 0 End) As MovComp

	From	Do Left Outer Join MGCausale On MGCausale.Cd_MGCausale      = Do.Cd_MGCausale

				Left Outer Join DoDoPrel  On  DODoPrel.Cd_Do_Prelevabile = Do.Cd_Do

	Where Do.Cd_Do = <<Format4SPT(This.value)>>

EndText



oCauInfo = xSqlExec2Obj(cStmt, .T.)



cDOAlias = This.FKAlias



With ThisForm.PF.pgGenerale

	** Imposta modalità Cliente/Fornitore

	If &cDOAlias..TipoDocumento = 'P'

		.txtCd_CF.Field.FKMode = Iif(&cDOAlias..CliFor == 'C', 5, Iif(&cDOAlias..CliFor == 'F', 6, 0))	&& per i Preventivi si possono usare anche i Potenziali Cli/For

	Else

		.txtCd_CF.Field.FKMode = Iif(&cDOAlias..CliFor == 'C', 1, Iif(&cDOAlias..CliFor == 'F', 2, 0))

		.PF.pgGenerale.txtCF_Fatt.Field.FKMode = .txtCd_CF.Field.FKMode

	EndIf



	With .PF.pgGenerale.txtCd_LS

		.Field.FKSelect  = 'SELECT * FROM LS WHERE LS.Cd_LS = <TEXT> AND LS.TipoLS != ' + Iif(&cDOAlias..CliFor == 'C', '2', '1')

		.Field1.FKSelect = .Field.FKSelect

		.Field2.FKSelect = .Field.FKSelect

**		.Field2.Visible  = oCauInfo.MovComp

	EndWith



	** AbiCab Banca Appoggio e CGConto Banca Sconto per fatture/note accredito/bolle/ordini/preventivi/rapportini

	.PF.pgGenerale.cntDatiContabili.txtCd_CGConto_BnSc.Visible = InList(&cDOAlias..TipoDocumento, 'F', 'A', 'N', 'B', 'O', 'P', 'D', 'G', 'M')



	** Visualizzo il flag Corrispondenza iva-merce solo se è un documento da contabilizzare

	.PF.pgGenerale.cntDatiContabili.chkCGCorrispondenzaIvaMerce.Visible = oCauInfo.Contabile



EndWith



ThisForm.Cd_MGCausale	= xDefault(oCauInfo.Cd_MGCausale, '')

ThisForm.Cd_MG_A     	= oCauInfo.Cd_MG_A

ThisForm.Cd_MG_P  		= oCauInfo.Cd_MG_P

ThisForm.MagAFlag 		= xDefault(oCauInfo.MagAFlag, 	.F.)

ThisForm.MagPFlag 		= xDefault(oCauInfo.MagPFlag, 	.F.)

ThisForm.MagAFix  		= xDefault(oCauInfo.UIMagAFix, 	.F.)

ThisForm.MagPFix  		= xDefault(oCauInfo.UIMagPFix, 	.F.)

ThisForm.IsPrelevabile	= !IsNull(oCauInfo.Id_DodoPrel	   )



** A seconda dei valori precedentemente settati rende enable/disable "visible"/"invisible"

** le colonne relative ai codici magazzino/ubicazione

With ThisForm.PF.pgGenerale.PF

	Iif(.pgRighe.ControlCount > 0, .pgRighe.Cnt.ModifyColumnsLook(), .T.)

	Iif(.pgPiede.ControlCount > 0, .pgPiede.Cnt.ModifyColumnsLook(), .T.)

EndWith



&& In inserimento il campo DoTes.DoBitMask è vuoto quindi valorizzo la variabile con il valore della funzione DoTypeAsMask()

nDoBitMask = Evl(DoTes.DoBitMask, DoTypeAsMask(This.FKRecord.TipoDocumento, This.FKRecord.CliFor))



** ---------------------------------------------------------------------------------

** Per i documenti IVA del ciclo passivo limito a 15 caratteri il campo NumeroDocRif

*Thisform.PF.PgGenerale.PF.PgGenerale.txtNumeroDataRif.Field.InputMask = Replicate('X', Iif(BitAnd(nDoBitMask, TD_CP_DOCIVA) != 0, 15, 20))

Thisform.PF.PgGenerale.PF.PgGenerale.txtNumeroDataRif.Field.InputMask = Replicate('X', 20)



** ---------------------------------------------------------------------------------

** Scheda di trasporto

If PemStatus(Thisform.PF.PgGenerale.PF.PgPiede, 'cnt', 5)

	Thisform.PF.PgGenerale.PF.PgPiede.cnt.ShowSchedaTrasporto(nDoBitMask)

EndIf 



** Nota IVa non serve la pagine del piede

** ThisForm.PF.pgGenerale.PF.pgPiede.Enabled = !&cDOAlias..Fte_NotaIva



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



**	N.B.: Questo metodo viene chiamato anche in caso si vada in editing di un documento e pertanto non è detto

**			che il valore sia effettivamente cambiato...



Local oDoRec



oDoRec = This.FKRecord



RefreshField(This)



With ThisForm.PF.pgGenerale



	** Valorizzo il campo DOTES.DOBitMask, Clifor (Parametri funzionamento -> meglio metterli in testa al metodo)

	Replace ;

		DoBitMask 			With DoTypeAsMask(oDoRec.TipoDocumento, oDoRec.CliFor) ;

		Clifor 				With oDoRec.Clifor ;

		Tipodocumento		With oDoRec.TipoDocumento ;

		SegnoDocumento		With Iif(oDoRec.TipoDocumento == 'N', -1, 1) ;

		Cd_MGCausale		With oDoRec.Cd_MGCausale ;

		DIEnabled			With oDoRec.DIEnabled ;

		DIExecutive			With oDoRec.DIExecutive ;

		DISave				With oDoRec.DISave ;

		FTE_AutoTipo		With oDoRec.FTE_AutoTipo ;

		In DoTes



	** Forzo il caricamento dei moduli stampa di default

	*.PF.pgModuli.cnt.grid.Refresh(.T.)

	RecSignClear(.PF.pgModuli.Cnt.Grid)

	.PF.pgModuli.Cnt.Grid.Refresh()



	** Nel caso il tipo documento sia dello stesso tipo mantengo la stessa data di registrazione dell'ultimo documento inserito

	If !IsNull(Thisform.oRecPrev) And Thisform.oRecPrev.TipoDocumento == oDoRec.TipoDocumento

		.txtDataDoc.Field.SetValue(Ttod(Thisform.oRecPrev.DataDoc))

	Else

		.txtDataDoc.Field.SetValue(Date())

	EndIf

	

	If BitAnd(ThisForm.Mode, FEDIMODE_INS) != 0 And BitAnd(ThisForm.Mode, FEDISUBMODE_INS_DUP) = 0

		If oDoRec.UIPropDataOra And oDoRec.TipoDocumento $ 'AB'

			ThisForm.PF.pgGenerale.PF.pgPiede.Cnt.CntDDT.txtTrasporto.Field1.Value = Datetime()

		EndIf

	EndIf



	If BitAnd(ThisForm.Mode, FEDIMODE_INS) != 0 And BitAnd(ThisForm.Mode, FEDISUBMODE_INS_DUP) = 0

		If oDoRec.UIPropDataConsegna 

			ThisForm.PF.pgGenerale.PF.pgGenerale.cntVarie.txtDataConsegna.Field.Value = Datetime()

		EndIf

	EndIf

	

	If (ThisForm.Mode = FEDIMODE_EDIT Or BitAnd(ThisForm.Mode, FEDIMODE_INS) != 0) And;

			((BitAnd(ThisForm.Mode, FEDIMODE_INS) != 0 And IsEmpty(xOldValue)) Or ;

			xMessageBox(Thisform.TB_(,'4597D21F-9964-4F8A-83F9-DC08C1CCC0C9', 'Riproporre i default del tipo documento %1! ?', This.Value), 4 + 32) == 6)



		** Non dovrebbe essere scatenato dall'evasione interattiva in quanto vengono popolati i cursori

		** senza scatenare l'onvaluechange (stesso concetto per cd_cf e cd_pg)

		If ThisForm.ModeFromPrelievo != 1

			** Considero solo le Spese varie in quanto le altre sul documento dipendono dal tipo pagamento

			ThisForm.CalcSpese(0x02)

			** Preservo il valore impostato per il flag nel tipo documento, mentre per lo stato di

			** prelevabilità (che è legato al documento specifico e non al tipo) imposto il valore

			** di default

			.PF.pgGenerale.cntStato.chkEsecutivo.Value    = oDoRec.Esecutivo

			.PF.pgGenerale.cntStato.chkPrelevabile.Value	 = oDoRec.Prelevabile

			.PF.pgGenerale.cntStato.chkModificabile.Value = oDoRec.Modificabile

		EndIf



	EndIf



	** Non serve gestire l'edit in quanto il campo non è abilitato in edit ma solo in inserimento

	.PF.pgPiede.Cnt.cntFattura.chkSpeseBolli.Visible = (oDoRec.TipoDocumento $ 'FAN' And oDoRec.CliFor = 'C')

	.PF.pgPiede.Cnt.TipoSpesaDisplay(oDoRec.TipoDocumento, .T.)

	.PF.pgPiede.Cnt.cntDdt.Refresh() && aggiorna situazione pulsanti calcolo pesi, volumi e colli in base al tipo documento



	Thisform.PF.PgGenerale.PF.pgInfo.edtNotePiede.DoBitMask = DoTes.DoBitMask



	If BitAnd(ThisForm.Mode, FEDIMODE_INS) != 0

		** La corrispondenza iva merce viene impostata anche sui documenti non contabili in quanto viene richiesto il conteggio iva

		Replace CGCorrispondenzaIvaMerce With Impostazione.CGCorrispondenzaIvaMerce In DoTes

		This.parent.parent.PF.pgGenerale.cntDatiContabili.chkCGCorrispondenzaIvaMerce.Refresh()

	EndIf



	** DOCIVATI **

	Replace ImportiIvati With oDoRec.ImportiIvati In DoTes	

	If oDoRec.ImportiIvati

		.txtCd_VL.Field.SetValue('EUR')					&& i documenti ivati posso essere solo in EUR

		.PF.pgGenerale.txtCF_Fatt.Visible = .F.		&& i documenti ivati posso essere gestire il Cliente di Fatturazione

	EndIf 

	.txtCd_VL.Field.Enabled = !oDoRec.ImportiIvati



**		** DOCIVATI: niente acconti fissi o abbuoni

**		.PF.pgPiede.Cnt.cntFattura.txtAbbuono		  .Visible = .PF.pgPiede.Cnt.cntFattura.txtAbbuono.Visible And !oDoRec.ImportiIvati

**		.PF.pgPiede.Cnt.cntFattura.txtAcconto.Field1.Visible = !oDoRec.ImportiIvati  

**		.PF.pgPiede.Cnt.cntFattura.txtAcconto.Label1.Visible = !oDoRec.ImportiIvati  



	** DOCIVATI

	.PF.pgPiede.Cnt.cntFattura.Grid.ColImportoV.Header1.Caption = 'Importo' + Iif(DoTes.ImportiIvati, ' Ivato', '')

	** le spese non sono gestite

	.PF.pgPiede.Cnt.cntFattura.Grid.Visible 			 = !DoTes.ImportiIvati

	.PF.pgPiede.Cnt.cntFattura.Title.Visible 	 		 = !DoTes.ImportiIvati

	.PF.pgPiede.Cnt.cntFattura.chkSpeseBolli.Visible = !DoTes.ImportiIvati



	Thisform.Toolbar.Buttons('FTEXML').Enabled 	= Thisform.Fte_Isxml()

	Replace FatturaElettronica With Nvl(xSQLExec2Var(Textmerge('Select CN.FatturaElettronica From CN Join DO On CN.Cd_CN = DO.Cd_CN Where DO.Cd_DO = <<FormatC4Spt(DoTes.Cd_DO)>>')), .F.) In Dotes

	

	** Acconto e Abbuono non gestiti per fattura elettronica

**		If PemStatus(Thisform.PF.PgGenerale.PF.PgPiede, 'cnt', 5)

**			** L'arrotondamento del netto a pagare inibisce l'utilizzo del campo abbuono in UI

**			Thisform.PF.PgGenerale.PF.PgPiede.Cnt.CntFattura.TxtAbbuono.Visible = IsEmpty(oDoRec.ArrotondamentoN) And !DoTes.FatturaElettronica

**			Thisform.PF.PgGenerale.PF.PgPiede.Cnt.CntFattura.txtAcconto.Visible = !DoTes.FatturaElettronica

**		EndIf



	**

	If PemStatus(Thisform.PF.PgGenerale.PF.PgPiede, 'cnt', 5)

		** L'arrotondamento del netto a pagare inibisce l'utilizzo del campo abbuono in UI

		Thisform.PF.PgGenerale.PF.PgPiede.Cnt.CntFattura.TxtAbbuono.Visible = IsEmpty(oDoRec.ArrotondamentoN)

	EndIf

	

EndWith



** AUTOTD -> Imposto i valori al cambio del tipodoc

Thisform.AutoTD_Set('DO')



** Gestione delle DI per i documenti generati con "Nuovo con duplicazione"

If BitAnd(ThisForm.Mode, FEDIMODE_EDIT) = 0 And BitAnd(ThisForm.Mode, FEDISUBMODE_INS_DUP) != 0

	** Ripulisco la DI da qualsiasi documento che sto generando

	ThisForm.DOIntento_Clear()

	

	** Inserisco la DI per il nuovo documento (se presente la gestione della stessa)

	ThisForm.DOIntento_Apply()

EndIf



ENDPROC

PROCEDURE GotFocus

DoDefault()



If PemStatus(This, 'ValueOnRecPrev', 5) And !IsEmpty(This.ValueOnRecPrev)

	This.Value = This.ValueOnRecPrev

	This.ValueOnRecPrev = Null

EndIf 



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: fedi.PF.pgGenerale.txtDataDoc) ***
*** PROPERTIES ***
Comment = "39AF63C9-2F45-4C33-8250-CABD1C29F851"

ControlSource = "dotes.datadoc"

Top = 11

Width = 63

required = .T.

Name = "Field"


*** METHODS ***
PROCEDURE onvaluechange

LParameters xOldValue



If !IsEmpty(xOldValue)

	Local cCd_VL, cMsg



	cCd_VL = Thisform.PF.pgGenerale.txtCd_VL.field.Value

	

	IF !(cCd_VL == 'EUR') 

		Local oRec, oDataRif, cDoAlias

		

		oDataRif = Thisform.PF.pgGenerale.PF.pgGenerale.txtNumeroDataRif.Field1

		cDoAlias = Thisform.PF.pgGenerale.txtCd_DO.Field.FKAlias

		

		If IsEmpty(oDataRif.Value) Or !(Evaluate(cDoAlias + '.TipoDocumento') $ 'FNA') Or !(Evaluate(cDoAlias + '.CliFor') == 'F')

			oRec = GetFixing_2Obj(cCd_VL, This.Value)

		Else

			oRec = GetFixing_2Obj(cCd_VL, oDataRif.Value)

		EndIf 



		If !IsNull(oRec.Cambio) And oRec.Cambio != This.Parent.Parent.txtCambio.Field.Value

		

			Text To cMsg NoShow Pretext 1+2

				Alla data del documento il cambio proposto per %1! (%2!) risulta diverso.

				

				Aggiornare il cambio?

			EndText 

		

			If xMessageBox(Thisform.TB_(,'EA142196-4D42-4625-8DCD-16B964581D62', cMsg, cCd_VL, LTrim(Tran(oRec.Cambio, This.Parent.Parent.txtCambio.Field.InputMask))), MB_YESNO + MB_ICONQUESTION) = IDYES 

				This.Parent.Parent.txtCambio.Field.SetValue(oRec.Cambio)

				

				If !SafeCompare(Ttod(oRec.DataCambio), This.Value)

					xMessageBox(Thisform.TB_(,'65A13BD5-4F60-4B2F-BAB1-D9D5347CDFE4', "Il cambio proposto per %1! risale al %2!.", cCd_VL, Dtoc(oRec.DataCambio)), MB_OK + MB_ICONINFORMATION)

				EndIf 

			EndIf 

		EndIf 

	EndIf

	

	

	** Se modifico la data documento "in avanti", controllo che le date consegna non siano antecedenti alla nuova data

	If This.Value > xOldValue



		Local nOldWA

		Local lDataConsT, lDataConsR, lDataTrasp

		

		** Controllo data Consegna della Testa

		If !IsEmpty(DoTes.DataConsegna) And DoTes.DataConsegna < This.Value 

			lDataConsT = .T.

		EndIf 



		** Controllo data Consegna delle Righe		

		nOldWA = Select(0)

		Select DORig

		Scan For !IsEmpty(DoRig.DataConsegna) And DoRig.DataConsegna < This.Value

			lDataConsR = .T.

			Exit

		EndScan 

		Locate

		Select (nOldWA)	



		** Controllo data Trasporto della Testa	

		If !IsEmpty(DoTes.TrasportoDataOra) And DoTes.TrasportoDataOra < This.Value 

			lDataTrasp = .T.

		EndIf 



		cMsg = ''

		If lDataConsT

			cMsg = cMsg + Thisform.TB_(, "CE3AC11B-2814-4431-8B64-48350AD60B88", ', la data consegna di testa')

		EndIf

		If lDataConsR

			cMsg = cMsg + Thisform.TB_(, "F24EA84A-9293-44EB-BE36-4328D3AC84F0", ', la data consegna di riga')

		EndIf

		If lDataTrasp

			cMsg = cMsg + Thisform.TB_(, "87F564BB-6209-4D07-9D37-C244935F41D2", ', la data di trasporto')

		EndIf



		If !IsEmpty(cMsg) And xMessageBox(Thisform.TB_(, "1FEB2D82-5B35-4913-B145-9C1191305BD1", 'È stata modificata la data documento ed è necessario adeguare %1!.' + CRLF + CRLF + 'Si vuole modificare tali valori impostandoli uguali alla data documento?', Substr(cMsg, 3)), 32+4) = 6



			** Controllo data Consegna della Testa

			If !IsEmpty(DoTes.DataConsegna) And DoTes.DataConsegna < This.Value 

				Replace DataConsegna With This.Value In DoTes

				This.Parent.Parent.PF.PgGenerale.cntVarie.txtDataConsegna.Refresh()

				lDataConsT = .T.

			EndIf 



			** Controllo data Consegna delle Righe		

			nOldWA = Select(0)

			Select DORig

			Scan For !IsEmpty(DoRig.DataConsegna) And DoRig.DataConsegna < This.Value

				Replace DataConsegna With This.Value In DoRig

				lDataConsR = .T.

			EndScan 

			Locate

			Select (nOldWA)	



			** Controllo data Trasporto della Testa	

			If !IsEmpty(DoTes.TrasportoDataOra) And DoTes.TrasportoDataOra < This.Value 

				Replace TrasportoDataOra With This.Value In DoTes

				This.Parent.Parent.PF.PgPiede.cnt.cntDDT.txtTrasporto.Refresh()

				lDataTrasp = .T.

			EndIf 



		EndIf 

		

	EndIf

	

EndIf



oRec = xSqlExec2Obj("Select dbo.afn_MGEsercizio(" + Format4Spt(This.Value) + ") As Cd_MGEsercizio")

If Vartype(oRec) == 'O' And !IsEmpty(oRec.Cd_MGEsercizio)

	Replace Cd_MGEsercizio With oRec.Cd_MGEsercizio In DoTes

Else

	xMessageBox(Thisform.TB_(,'9CA39CFE-75D0-48E7-BF8E-4C5651260048', "Alla data del documento non è codificato alcun esercizio di magazzino."), MB_OK + MB_ICONINFORMATION)

Endif



** Causale / Data Doc sono i campi su cui si basa il calcolo

** Chiedo all'utente se è necessario ricalcolare i dati dei RR

** ----- LICADAPTER

If !IsEmpty(xoldvalue) And ;

	Reccount('DoRig') > 0 And ;

	Evaluate(ThisForm.PF.pgGenerale.txtCd_DO.Field.FKAlias + '.RR_Enabled') And ;

	oApp.LicInfo.CG_Main And ;

	xMessageBox(Thisform.TB_(,'EE95FB3F-D928-437E-9360-60E08FDB9C52', 'Ricalcolo i dati relativi ai ratei e risconti in base alla nuova data?'), MB_IQYNDB2) = IDYES

	

	Thisform.RR_Reload()

EndIf



** Applico nuovi criteri di esenzione indipendentemente dall'applicazione dei nuovi default

If Thisform.DOIntento And !IsEmpty(xOldValue) And !SafeCompare(xOldValue, This.Value) And ;

	(!DoTes.DISave Or Bitand(Thisform.Mode, FEDIMODE_INS_DUP) = 0) And ;

	Reccount('DoRig') > 0 And ;

	xMessageBox(Thisform.TB_(,'700A34EC-AEA8-47CB-B49B-CB457A1775B0', 'Applico dichiarazione intento in base alla nuova data?'), MB_IQYNDB2) = IDYES



	** Ripulisco i dati per dichiarazione intento se cambio data

	Thisform.DoIntento_Clear()



	** Riapplico in base alla nuova data

	Thisform.DoIntento_Apply()

	

EndIf



Return DoDefault(xOldValue)

ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



Local dDate

Local oCF



** Licenze a tempo

dDate = This.Value

If !oApp.LicInfo.TestExpireDate(@dDate)

	This.Value = dDate

EndIf 



Return DoDefault(lIsChanged, xOldValue)

ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: fedi.PF.pgGenerale.txtCd_CF_Auto) ***
*** PROPERTIES ***
ControlSource = "DoTes.Cd_CF_Auto"

Height = 19

Left = 0

Top = 11

Width = 52

ZOrderSet = 1

fkmode = 2

fktabledesc = Anagrafica

fkhasdisplay = .F.

required = .T.

checkfor = 1

Name = "Field"


*** METHODS ***
PROCEDURE Init

IF !DODEFAULT()

	RETURN .F.

ENDIF



THIS.AddProperty('oScontiGruppoClasse', .F.)



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



DoDefault(xOldValue)



If !This.Visible

	Return .T.

EndIf



ThisForm.PF.pgGenerale.cntTesta2.Refresh()





ENDPROC

PROCEDURE contextmenuproc

Lparameters nCBMId, xPar1, xPar2



Do Case



	Case nCBMId == CMM_ADD_ITEMS_TO_CONTEXT_MENU



		Return DoDefault(nCBMId, xPar1) 	



	Case nCBMId == CMM_ADD_ITEMS_TO_EDIT_PAD

		

		Return DoDefault(nCBMId, xPar1) 	

		

	Case nCBMId == CMM_PROCESS_CHOICE



		xRet = DoDefault(nCBMId, xPar1)

		

		** il seguente codice viene eseguito per aggiornare lo stato di visualizzazione dei campi relativi alla sede operativa e alla sede diversa

		If xPar1 == MB_EDIT_SRCHFEDI

			This.OnRefresh() 	

		EndIf 

			

		Return xRet

EndCase

ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



Local vRet



vRet = DoDefault(lIsChanged, xOldValue)



If !IsEmpty(vRet) And lIsChanged And This.Visible



	vRet = Thisform.AutoTD_Chk('CF_AUTO')

	ThisForm.PF.pgGenerale.cntTesta2.Refresh(.T.)



EndIf



Return vRet

ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: fedi.PF.pgGenerale.txtCd_CF) ***
*** PROPERTIES ***
ControlSource = "DoTes.Cd_CF"

Height = 19

Left = 0

Top = 11

Width = 52

ZOrderSet = 1

fktabledesc = Anagrafica

fkhasdisplay = .F.

required = .T.

checkfor = 1

Name = "Field"


*** METHODS ***
PROCEDURE fkselect_access

Local cWhere



cWhere = DoDefault()

cWhere = cWhere + Iif(!IsEmpty(cWhere) And ThisForm.PF.pgGenerale.txtCd_DO.Field.FKRecord.FTE_AutoTipo = 1 And ThisForm.PF.pgGenerale.txtCd_DO.Field.FKRecord.FTE_AutoOnly, Textmerge(' And CF.FTE_AutoTipo = <<ThisForm.PF.pgGenerale.txtCd_DO.Field.FKRecord.FTE_AutoTipo>>'), '')



Return cWhere







ENDPROC

PROCEDURE contextmenuproc

Lparameters nCBMId, xPar1, xPar2



Do Case



	Case nCBMId == CMM_ADD_ITEMS_TO_CONTEXT_MENU



		Return DoDefault(nCBMId, xPar1) 	



	Case nCBMId == CMM_ADD_ITEMS_TO_EDIT_PAD

		

		Return DoDefault(nCBMId, xPar1) 	

		

	Case nCBMId == CMM_PROCESS_CHOICE



		xRet = DoDefault(nCBMId, xPar1)

		

		** il seguente codice viene eseguito per aggiornare lo stato di visualizzazione dei campi relativi alla sede operativa e alla sede diversa

		If xPar1 == MB_EDIT_SRCHFEDI

			This.OnRefresh() 	

		EndIf 

			

		Return xRet

EndCase

ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



** Cli/For

Local cCFAlias, cDOAlias, cStmt

Local oRec, oDOTes



**	If !This.Visible

**		Return .T.

**	EndIf



** Impostazione Tipo di Blocco per gli articoli

ThisForm.PF.pgGenerale.PF.pgRighe.Cnt.Grid.ColCd_AR.stdText1.CheckFor = This.FkMode



cCFAlias = This.FKAlias

cDOAlias = This.Parent.Parent.txtCd_DO.Field.FKAlias



RefreshField(This)



** Applico nuovi criteri di esenzione indipendentemente dall'applicazione dei nuovi default

** Il cambio del cliente in qualsiasi caso deve rivalutare tutta l'applicazione della dichiarazione.

** In caso codice vuoto non viene applicato nulla dopo la pulizia

** Mostro le colonne solo se necessario



** Devo abilitare la gestione prima del calcolo delle spese (CALCSPESE)

Iif(!SafeCompare(xOldValue, This.Value), Thisform.DoIntento_Visible(.T.), .T.)



If (ThisForm.Mode = FEDIMODE_EDIT Or BitAnd(ThisForm.Mode, FEDIMODE_INS) != 0) And;

      ((BitAnd(ThisForm.Mode, FEDIMODE_INS) != 0 And IsEmpty(SubStr(Evl(xOldValue, ''), 2))) Or ;

      xMessageBox(Thisform.TB_(,'13E16ED3-C287-431F-8193-753C60F83D68', 'Riproporre i default del cliente %1! ?', This.Value ), 4 + 32) == 6)



   oDoTes = DoTes_Defaults_2Obj(&cDOAlias..Cd_DO, &cCFAlias..Cd_CF, xDefault(DoTes.DataDoc, Date()))



   ThisForm.SkipRicalcoloScontoCassa = .T.



   This.oScontiGruppoClasse = xSqlExec2Obj(;

      "SELECT  " +;

      "	CF.Cd_DOVettore,  " +;

      "	CF.Cd_DOSped,  " +;

      "	CF.Cd_DOPorto,  " +;

      "	ISNULL(CFGruppo1.Sconto, '') AS CFFamiglia,  " +;

      "	ISNULL(CFGruppo2.Sconto, '') AS CFGruppo,  " +;

      "	ISNULL(CFGruppo3.Sconto, '') AS CFSottoGruppo,         " +;

      "	ISNULL(CFClasse1.Sconto, '') AS CFCategoria,  " +;

      "	ISNULL(CFClasse2.Sconto, '') AS CFClasse,  " +;

      "	ISNULL(CFClasse3.Sconto, '') AS CFSottoClasse  " +;

      "FROM CF " +;

      "	INNER JOIN CFGruppo1	ON CFGruppo1.Cd_CFGruppo1 = CF.Cd_CFGruppo1 " +;

      "	INNER JOIN CFGruppo2 ON CFGruppo2.Cd_CFGruppo1 = CFGruppo1.Cd_CFGruppo1 AND CFGruppo2.Cd_CFGruppo2 = CF. Cd_CFGruppo2 " +;

      "	INNER JOIN CFGruppo3 ON CFGruppo3.Cd_CFGruppo2 = CFGruppo2.Cd_CFGruppo2 AND CFGruppo3.Cd_CFGruppo1 = CFGruppo2.Cd_CFGruppo1 AND CFGruppo3.Cd_CFGruppo3 = CF.Cd_CFGruppo3 " +;

      " " +;

      "	INNER JOIN CFClasse1	ON CFClasse1.Cd_CFClasse1 = CF.Cd_CFClasse1 " +;

      "	INNER JOIN CFClasse2 ON CFClasse2.Cd_CFClasse1 = CFClasse1.Cd_CFClasse1 AND CFClasse2.Cd_CFClasse2 = CF. Cd_CFClasse2 " +;

      "	INNER JOIN CFClasse3 ON CFClasse3.Cd_CFClasse2 = CFClasse2.Cd_CFClasse2 AND CFClasse3.Cd_CFClasse1 = CFClasse2.Cd_CFClasse1 AND CFClasse3.Cd_CFClasse3 = CF.Cd_CFClasse3 " +;

      "WHERE CF.Cd_CF = " + Format4Spt(This.Value))



   With ThisForm.PF.pgGenerale   



      .txtCd_VL.Field.SetValue(xDefault(oDoTes.Cd_VL, 'EUR'))



		TEXT TO cStmt TEXTMERGE NOSHOW

			SELECT

				(SELECT Count(*) FROM CFDest WHERE Cd_CF = <<Format4Spt(DoTes.Cd_CF)>>) AS NumDestDiv,

				(SELECT Count(*) FROM CFSede WHERE Cd_CF = <<Format4Spt(DoTes.Cd_CF)>>) AS NumSedeAmm

		ENDTEXT

      oRec = xSqlExec2Obj(cStmt)



      If IsEmpty(oRec.NumDestDiv)

         .txtCFDest.Field.Value = Null

      Else

         .txtCFDest.Field.Value = Iif(IsEmpty(oDoTes.Cd_CFDest), Null, oDoTes.Cd_CFDest)

      EndIf

      .cntTesta2.Refresh()



      If IsEmpty(oRec.NumSedeAmm)

         .txtCFSede.Field.Value = Null

      Else

         .txtCFSede.Field.SetValue(Iif(IsEmpty(oDoTes.Cd_CFSede), Null, oDoTes.Cd_CFSede))

      EndIf



   EndWith



   With ThisForm.PF.pgGenerale.PF.pgPiede.Cnt.CntDDT

      .txtVettore1.Field.SetValue   (oDoTes.Cd_DOVettore_1)

      .txtVettore2.Field.SetValue   (oDoTes.Cd_DOVettore_2)

      .txtSpedizione.Field.SetValue (oDoTes.Cd_DOSped)

      .txtPorto.Field.SetValue      (oDoTes.Cd_DOPorto)

      .txtTrasporto.Field.SetValue  (oDoTes.Cd_DOTrasporto)

      .txtAspettoBeni.Field.SetValue(oDoTes.Cd_DOAspBene)

   EndWith



   With ThisForm.PF.pgGenerale.PF.pgGenerale

	

      .cntPagamento.txtCd_Agente.Field.SetValue	  (oDoTes.Cd_Agente_1)

      .cntPagamento.txtCd_Agente.Field1.SetValue  (oDoTes.Cd_Agente_2)



      .txtCd_LS.Field.SetValue  					(oDoTes.Cd_LS_1)

      .txtCd_LS.Field1.SetValue  				(oDoTes.Cd_LS_2)

      .txtCd_LS.Field2.SetValue  				(oDoTes.Cd_LS_C)



      .cntVarie.txtCd_CFZona.Field.SetValue	(oDoTes.Cd_CFZona)



      .txtCF_Fatt.Field.SetValue  				(oDoTes.Cd_CF_Fatt, .t.)



      If .cntDatiContabili.txtIban.Visible

         .cntDatiContabili.txtIban.Field.SetValue(oDoTes.Iban)

         .cntDatiContabili.txtBic.Field.SetValue(oDoTes.BicCode)

         

         If .cntDatiContabili.txtCd_CGConto_BnSc.Visible

	         .cntDatiContabili.txtCd_CGConto_BnSc.Field.SetValue(oDoTes.Cd_CGConto_Banca)

			EndIf 

      EndIf



      .cntPagamento.txtCd_PG.Field.SetValue(oDoTes.Cd_PG)

      

		** Sia l'aliquota delle spese doc che varie è legata all'aliquota del CF/Dest se richiesto (è tutto gestito all'interno delle procedure server)

		Iif(!This.IsEmpty() And !.cntPagamento.txtCd_PG.Field.IsEmpty(), ThisForm.CalcSpese(0x01), .T.)

		Iif(!This.IsEmpty(), ThisForm.CalcSpese(0x02), .T.)



   EndWith



   ThisForm.SkipRicalcoloScontoCassa = .F.

   ThisForm.EvalScontoCassa()



   ** Propongo il flag di addebito spese bolli

   ThisForm.PF.pgGenerale.PF.pgPiede.Cnt.CntFattura.chkSpeseBolli.SetValue(Thisform.GetSpeseBolliFlag())



	Thisform.Toolbar.Buttons('FTEXML').Enabled = Thisform.Fte_Isxml()

	If !Thisform.Toolbar.Buttons('FTEXML').Enabled

		** non è una fattura elettronica

		Replace Fte_XML With Null In DoTes

	Else

		** devo impostare, per i clienti CONDOMINIO, il tipo reditto

		If This.FKRecord.Condominio

			Local oXml, oNode		

			oXml = NewDomDocument(NEvl(DoTes.Fte_Xml, '<rows><row/></rows>'))

			oNode = oXml.SelectSingleNode('rows/row')

			oNode.setAttribute('dg_causalepagamento', NEvl(xSqlExec2Var('Select Cd_TipoReddito From RAAnagrafe Where Cd_CF = ' + FormatC4Spt(This.Value)), ''))

		

			Replace Fte_Xml With oXml.Xml In DoTes					

		EndIf 

	EndIf

	

	Thisform.SetRegimeIva('CF', xOldValue)

	Thisform.SetRegimeIva('USERINTERFACE')

	

   ** Default per CA

   ** Chiedo all'utente se riapplicare i default in caso di edit o ins dopo la seconda digitazione

   ** In caso di INS CF x la prima volta vado liscio



	** ----- LICADAPTER

   If &cDOAlias..CAEnabled And ;

   	oApp.LicInfo.CA_Main And ;

		Reccount('DoRig') + Reccount('DoRigSpesa') != 0 And ;

		( ;

			(BitAnd(ThisForm.Mode, FEDIMODE_INS) != 0 And IsEmpty(SubStr(Evl(xOldValue, ''), 2))) Or ;

			( ;

				(ThisForm.Mode = FEDIMODE_EDIT Or BitAnd(ThisForm.Mode, FEDIMODE_INS) != 0) And ;

				xMessageBox(Thisform.TB_(,'D1B5FA8F-63F3-49F3-BAD9-367F65394D3D', 'Ripropongo i default per i dati di contabilità analitica applicati alle righe articoli e spesa?'), 4 + 32) == IDYES ;

			) ;

		)



		Thisform.CA_SetDefaults()



   EndIf

	

EndIf



** Applico nuovi criteri di esenzione indipendentemente dall'applicazione dei nuovi default

** Il cambio del cliente in qualsiasi caso deve rivalutare tutta l'applicazione della dichiarazione.

** In caso codice vuoto non viene applicato nulla dopo la pulizia



If !SafeCompare(xOldValue, This.Value) And ;

	(!DoTes.DISave Or Bitand(Thisform.Mode, FEDIMODE_INS_DUP) = 0)



	** Ripulisco i dati per dichiarazione intento se cambio anagrafica

	Thisform.DoIntento_Clear()



	** Riapplico con il CF nuovo solo se prima era compilato

	Thisform.DoIntento_Apply()

	

EndIf

ENDPROC

PROCEDURE onrefresh

LParameters xOldValue



DoDefault()



** N.B.: Il refresh del Cli/For DEVE avvenire PRIMA del refresh della DestDiv

**			ed entrambi PRIMA del refresh del container con l'indirizzo



**	If !This.Visible

**		Return .T.

**	EndIf



Local oRec

Local cStmt

TEXT TO cStmt TEXTMERGE NOSHOW

	SELECT

		(SELECT Count(*) FROM CFDest WHERE Cd_CF = <<FormatC4Spt(DoTes.Cd_CF)>>) AS NumDestDiv,

		(SELECT Count(*) FROM CFSede WHERE Cd_CF = <<FormatC4Spt(DoTes.Cd_CF)>>) AS NumSedeAmm

ENDTEXT

oRec = xSqlExec2Obj(cStmt)



With This.Parent.Parent

   .txtCFDest.Visible = !IsEmpty(oRec.NumDestDiv)

   .txtCFSede.Visible = !IsEmpty(oRec.NumSedeAmm)

   .PF.pgGenerale.txtCF_Fatt.Field.fkmode = Iif(InList(Left(This.Value,1),'C','P'), 1, 2)

   .PF.pgGenerale.txtCF_Fatt.ToolTipText  = Iif(InList(Left(This.Value,1),'C','P'), 'Cliente', 'Fornitore') + ' cui intestare la fattura'

	.PF.pgGenerale.txtCF_Fatt.SetAll('Tooltiptext', .PF.pgGenerale.txtCF_Fatt.ToolTipText)

EndWith



ENDPROC

PROCEDURE Init

IF !DODEFAULT()

	RETURN .F.

ENDIF



THIS.AddProperty('oScontiGruppoClasse', .F.)





ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



Local vRet, oDoRec, oFormFido, oDOTotali, oCF

Local nSegno, nCurDoc



vRet = DoDefault(lIsChanged, xOldValue)



** Per i documenti integrativi il campo non è visibile per cui non vado a fare controlli

If !IsEmpty(vRet) And lIsChanged And This.Visible

	oDoRec = ThisForm.PF.pgGenerale.txtCd_DO.Field.FKRecord



	oCF = This.FKRecord

	If !IsEmpty(oCF.Cd_CF_Fatt)

		** Se c'è un cliente di fatturazione, prendo quest'ultimo (non controllo quello già inserito poichè l'OnValueChange va a sovrascriverlo)

		oCF = xSqlExec2Obj('Select * From CF Where Cd_CF = ' + FormatC4Spt(oCF.Cd_CF_Fatt))

	EndIf 



	If oDoRec.UIchkFido And oCF.Fido != 0 

		oDOTotali = ThisForm.TotaleDocumento()

		nSegno = IIF(oDorec.TipoDocumento = 'N', -1, 1)

		nCurDoc = IIF(INLIST(oDorec.TipoDocumento, 'F', 'A', 'N'), oDoTotali.TotAPagareE, oDoTotali.TotAPagareE - oDoTotali.TotImpostaE)



		oFormFido = NewObjectWCR5('ControlloFido_Ahts', 'Forms\Fedi_DocCommon.vcx', '',	oCF.Cd_CF, !oDoRec.UIchkFidoBo, !oDoRec.UIchkFidoOC, nCurDoc * nSegno, DoTes.Id_DoTes)

		If Vartype(oFormFido) = 'O'

			If oDoRec.UIchkFidoVis Or oFormFido.Differenza < 0

				oFormFido.Show(1)

				Inkey(0.1, "H")

			EndIf

			If oFormFido.Differenza < 0

				If oDoRec.UIchkFidoBlk

					xMessageBox(Thisform.TB_(,'41B910D1-2DA4-4040-9CE1-1A660120BA93', "Emissione Bloccata a causa del superamento del fido!!"), MB_ICONSTOP)

					vRet = 0

				Else

					If xMessageBox(Thisform.TB_(,'05D02541-12B5-4389-B0A7-65C0004FCE66', "Il fido è stato superato!! Si vuole proseguire ugualmente ?"), MB_YESNO + MB_ICONQUESTION + MB_DEFBUTTON2) = IDNO

						vRet = 0

					Else

						If oDoRec.UIChkFidoBlkE And DoTes.Prelevabile && Se già Prelevabile = .F. (es in modifica) non stresso l'operatore...

							xMessageBox(Thisform.TB_(,'5040EFA8-5006-4BB7-92AB-8FABBD0A9E3B', 'Il documento viene impostato come non prelevabile causa superamento del fido.'), MB_ICONINFORMATION)

							Thisform.PF.pgGenerale.PF.pgGenerale.cntStato.chkPrelevabile.SetValue(.F.)

						EndIf

					EndIf

				EndIf

			EndIf

			oFormFido.Release()

		EndIf

	EndIf



	** Fattura Elettronica

	If oApp.LicInfo.FatturaElettronica And InList(This.Parent.Parent.txtCd_DO.Field.FkRecord.TipoDocumento, 'F', 'A', 'N') And Left(DoTes.Cd_CF, 1) = 'C'

		If xSqlExec2Var('Select FatturaElettronica From CN Join DO On CN.Cd_CN = DO.Cd_CN Where DO.Cd_DO = ' + FormatC4Spt(DoTes.Cd_DO)) = .F.

			** Contatori NON elettronici

			Do Case

				Case  oCF.EntePubblico AND !IsEmpty(oCF.CodiceIPA)

					xMessageBox(Thisform.TB_(,'F78204B3-4213-9CCA-8EAF-2E33F0305540', [L'anagrafica è dotata di "Codice Ufficio PA". Non è possibile usare tale cliente in un documento NON elettronico.]), 16)

					vRet = 0

				Case !oCF.EntePubblico AND !IsEmpty(oCF.CodiceFPR) And !oCF.FE_Ignore_CodiceFPR

					xMessageBox(Thisform.TB_(,'1C438BEC-461F-BE3E-819B-6BE19B0CA4E8', [L'anagrafica è dotata di "Codice Dest/PEC B2B". Non è possibile usare tale cliente in un documento NON elettronico.]), 16)

					vRet = 0

			Endcase 	

		EndIf 

	EndIf 



	**

	This.Parent.Parent.cntTesta2.Refresh(.T.)	&& lRefreshLblLabel = .T. serve solo per visualizzare/nascondere la lblAlert



Endif



If !IsEmpty(vRet) And lIsChanged And This.Visible



	vRet = !IsEmpty(Thisform.Fte_Check('CF'))

	ThisForm.PF.pgGenerale.cntTesta2.Refresh(.T.)



EndIf



Return vRet



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: fedi.PF.pgGenerale.txtCd_VL) ***
*** PROPERTIES ***
ControlSource = "dotes.cd_vl"

Format = "!"

Height = 19

Left = 0

Top = 11

Width = 31

ZOrderSet = 1

fkselect = SELECT * FROM VL WHERE Cd_VL = <TEXT>

fktabledesc = Valute

fkdecodedfield = Descrizione

fkhasdisplay = .T.

required = .T.

Name = "Field"


*** METHODS ***
PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If DoTes.ImportiIvati And This.Value != 'EUR'

	Return .F.

EndIf  



Return DoDefault(lIsChanged, xOldValue)

ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



With This.Parent.Parent



	** E' preferibile in codice utilizzare EVAL(This.FKAlias + '.Decimali') anziché DoTes.Decimali,

	**	in ogni caso tengo DoTes.Decimali aggiornato qualora venisse utilizzato in codice nei vari eventi...

	** [22/05/2003 Bug 449] Queste operazioni è meglio farle prima del txtCambio.field.SetValue(...)

	** in quanto DoTes.decimali viene utilizzato nell'onvaluechange del cambio.

	Local oVLRec



	oVLRec = This.FKRecord 		&& Mi garantisce che venga aperta la WA This.FKAlias



	If DoTes.Decimali      != oVLRec.Decimali 

		Replace Decimali      With oVLRec.Decimali      In DoTes

	EndIf

	If DoTes.DecimaliPrzUn != oVLRec.DecimaliPrzUn

		Replace DecimaliPrzUn With oVLRec.DecimaliPrzUn In DoTes

	EndIf



	If This.Value == 'EUR'

		.txtCambio.Field.SetValue(1.0)

	Else

		Local oRec, dDataRif, oDoRec



		dDataRif = ThisForm.PF.pgGenerale.PF.pgGenerale.txtNumeroDataRif.Field1.Value

		oDoRec   = ThisForm.PF.pgGenerale.txtCd_Do.Field.FKRecord



		If !IsEmpty(dDataRif) And oDoRec.TipoDocumento $ 'FNA' And oDoRec.CliFor == 'F'

			oRec = GetFixing_2Obj(This.Value, dDataRif)

		Else

			oRec = GetFixing_2Obj(This.Value, .txtDataDoc.Field.Value)			

		EndIf



		If IsNull(oRec.Cambio)

			xMessageBox(Thisform.TB_(,'7A48B77F-68D6-43F1-9B59-829A229382D5', "Nessun cambio valido al %1! per %2!.", DToC(.txtDataDoc.Field.Value), This.Value), MB_OK + MB_ICONSTOP)

			.txtCambio.Field.SetValue(1.0)

		Else

			.txtCambio.Field.SetValue(oRec.Cambio)



			If !SafeCompare(TToD(oRec.DataCambio), .txtDataDoc.Field.Value) And !oRec.IsEuro

				xMessageBox(Thisform.TB_(,'4D321D79-390F-4E34-A212-F1C6480DD310', "Il cambio proposto per %1! risale al %2!", This.Value, DToC(oRec.DataCambio)), MB_OK + MB_ICONINFORMATION)

			EndIf

		EndIf

		*		.txtCambio.Field.SetValue(GetFixing(This.Value, .txtDataDoc.Field.Value))

	EndIf



EndWith





ENDPROC

PROCEDURE onrefresh

LParameters xOldValue



DoDefault(xOldValue)



Local oTxtCambio, oVLRec



oVLRec     = This.FKRecord

oTxtCambio = This.Parent.Parent.txtCambio.Field



ThisForm.SetPictureValuta()



oTxtCambio.Enabled = !(This.Value == 'EUR') And (!oVLRec.Euro Or oVLRec.EuroData > DoTes.DataDoc)

oTxtCambio.TabStop = oTxtCambio.Enabled



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: fedi.PF.pgGenerale.txtCambio) ***
*** PROPERTIES ***
Comment = "C38E2500-CB95-426A-95B9-C96D8467EEEA"

Anchor = 10

Alignment = 1

ControlSource = "dotes.cambio"

Height = 19

InputMask = "#####.######"

Left = 0

Top = 11

Width = 78

ZOrderSet = 1

required = .T.

Name = "Field"


*** METHODS ***
PROCEDURE onvaluechange

Lparameters xOldValue



Local nOldWA, nRecNo, nCount



DoDefault(xOldValue)



If IsEmpty(xOldValue)

	** se parto da un valore vuoto, non devo fare nulla

	Return

EndIf  



nOldWA = Select(0)



Select DoRigSpesa

nRecNo = Recno('DoRigSpesa')

Count To nCount For Empty(Perc)		&& non devo considerare le spese espresse in percentuale



** se modifico il cambio chiedo se si vuole ricalcolare il valore delle spese in base al nuovo Cambio.

** NB.: le spese, nella configurazione documento, sono espresse in EUR, quindi alla creazione del documento vengono convertite al Cambio iniziale: 

**      se tale valore cambia presubilmente bisogna cambiare il valore delle spese, ma non a tutti va bene. Quindi domando...



If nCount > 0 And xMessagebox('Si vuole ricalcolare gli importi delle righe spesa in base al nuovo valore del cambio?',4+32) = 6	&& IDYES

	Replace ;

		ImportoV 			With Round((ImportoV / xOldValue) * This.Value, DoTes.Decimali), ;

		ImportoEvadibileV With ImportoV ;

		IN DoRigSpesa All

Endif



Locate Record (nRecNo)

Select (nOldWA)





ENDPROC

PROCEDURE fkgetdata

Return DoTes.DataDoc

ENDPROC

PROCEDURE fkgetvl

Return DoTes.Cd_VL

ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: fedi.PF.pgGenerale.txtCFDest) ***
*** PROPERTIES ***
ControlSource = "dotes.Cd_cfdest"

Format = "!"

Height = 19

Left = 0

Top = 11

Width = 35

fkselect = SELECT * FROM CFDest WHERE CFDest.Cd_CFDest = <TEXT> AND CFDest.Cd_CF = 'X'

fktabledesc = Destinazioni

fkhasdisplay = .T.

builder = Development\ArcaBuilder.prg

Name = "Field"


*** METHODS ***
PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If !DoDefault(lIsChanged, xOldValue)

	Return .F.

EndIf



** Controlla Stato

Local oRec

Local nOldWA

Local cTipoBlocco, cMessage, cNoteCliFor



If This.IsEmpty()

	Return .T.

Endif



nOldWA = Select(0)



Select (This.FKAlias)



oRec = xSqlExec2Obj('Select * From CFStato Where Cd_CFStato = ' + Format4Spt(Cd_CFStato) + ' And TipoCF = ' + Format4Spt(TipoCF_1) )



If Vartype(oRec) = 'O'



	cTipoBlocco	= oRec.Documenti



	If (cTipoBlocco != 'N')



		cMessage	 	= oRec.MessageD

		cNoteCliFor = ''

		Do Case 

			Case oRec.AddNoteD = -1								&& Note Principali

				cNoteCliFor = Nvl(Rtrim(Note_CFDest), '')

			

			Case oRec.AddNoteD > 0 And !IsEmpty(NoteXml)	&& NoteXML

				

				Local oXml, oGNodes, oGNode

				

				oXml = NewDomDocument(NoteXml)

				oGNodes = oXml.selectNodes('rows/row')

				For Each oGNode In oGNodes	

					If Val(Nvl(oGNode.GetAttribute('nota'), 0)) = oRec.AddNoteD

						cNoteCliFor = Rtrim(oGNode.Text)

						Exit

					EndIf 

				Next 

		EndCase



		cMessage		= Chrtran(cMessage,	  '|', '')

		cNoteCliFor	= Chrtran(cNoteCliFor, '|', '')



		xMessageBox(TB_(,'6DB4FD63-1977-4196-A1FB-8F23D6E0E389', 'Controllo Sede Operativa Anagrafica.' + CRLF + '%1!' + CRLF + '%2!', cMessage, cNoteCliFor), Iif(cTipoBlocco == 'B', MB_ICONSTOP, MB_ICONEXCLAMATION))

	EndIf

Else

	cTipoBlocco = 'X'

Endif



Select (nOldWA)



Return !(cTipoBlocco == 'B')

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

PROCEDURE fkselect_access

Local cWhere

cWhere = ''

If (This.AnagraficheObsolete != 2)

	cWhere = ' And CFDest.Obsoleto = ' + Transform(This.AnagraficheObsolete)

EndIf



Return This.FKSelect + cWhere



ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



Local oRec

Local cDOAlias, cCFAlias, cCd_Agente



cCFAlias = This.Parent.Parent.txtCd_CF.Field.FKAlias

cDOAlias = This.Parent.Parent.txtCd_DO.Field.FKAlias



ThisForm.PF.pgGenerale.cntTesta2.Refresh()



** -----------------------------------------------------------------------------------------------------------

** Controllo se l'agente di default è diverso da quello già presenti nella testa documento



cCd_Agente = NEvl(Eval(This.FKAlias + '.Cd_Agente'), 	&cCFAlias..Cd_Agente_1)



If !SafeCompare(cCd_Agente, ThisForm.PF.pgGenerale.PF.pgGenerale.cntPagamento.txtCd_Agente.Field.Value) And ;

	xMessageBox(Iif(!IsEmpty(This.Value), Thisform.TB_(,'65CB6363-368B-413C-BB21-D89A27C82AE2', "Riproporre l'agente di default (%1!) della destinazione diversa %2! ?", 			Nvl(cCd_Agente, '<vuoto>'), This.Value	), ;

													  Thisform.TB_(,'C30F1CCE-940B-48FD-9B6B-DB4006772BAB', "Riproporre l'agente di default (%1!) del cliente senza destinazione diversa ?", 	Nvl(cCd_Agente, '<vuoto>')					)  ), 4 + 32) == 6



	ThisForm.PF.pgGenerale.PF.pgGenerale.cntPagamento.txtCd_Agente.Field.SetValue(cCd_Agente)

EndIf 



** -----------------------------------------------------------------------------------------------------------



** Bug: 1806

** Nel caso non fosse indicata la SO riprendo i dati di default del CF

** Nel caso fosse indicata la SO ma non presentasse i dati menzionati riprendo i dati di default del CF

ThisForm.PF.pgGenerale.PF.pgGenerale .cntVarie.txtCd_CFZona    .Field.SetValue(NEvl(Eval(This.FKAlias + '.Cd_CFZona'), 		&cCFAlias..Cd_CFZona))

ThisForm.PF.pgGenerale.PF.pgPiede.cnt.cntDDT.txtVettore1       .Field.SetValue(NEvl(Eval(This.FKAlias + '.Cd_DOVettore'), 	&cCFAlias..Cd_DOVettore))



** Sia l'aliquota delle spese doc che varie è legata all'aliquota del CF/Dest se richiesto (è tutto gestito all'interno delle procedure server)

If oApp.Preferenza.DOAliquotaSpese

			

	ThisForm.CalcSpese(0x01 + ;		&& 0x01	Spese Documento (Incasso + Effetti) 

							 0x02 + ;		&& 0x02	Spese Varie (in Cd_DO)

							 0x10  )			&& 0x10	aggiorno solo le Aliquote IVA									

EndIf



** Default per CA

** Chiedo all'utente se riapplicare i default 



** ----- LICADAPTER

If &cDOAlias..CAEnabled And ;

	!IsEmpty(xOldValue)  And ;

	oApp.LicInfo.CA_Main And ;

	xMessageBox(Thisform.TB_(,'DBD0AEA2-E446-423F-83B5-A20B85A80489', 'Ripropongo i default per i dati di contabilità analitica applicati alle righe articoli e spesa?'), 4 + 32) == 6



	Local nRC, oWA, oWA1

			 

	oWa = SelectWA('DoRig')

	Calculate CNT() FOR !IsEmpty(DoRig.Cd_Ar) To nRC IN DoRig

	

	oProg = NewProgressForm(nRC, 'Selezione dati di contabilità analitica in corso ... (' + Transform(nRC) + ')')

	oProg.Show()



	Scan For !IsEmpty(Cd_Ar)

		oProg.Advance(, Rtrim(DoRig.Cd_Ar) + ' - ' + Rtrim(DoRig.Descrizione))

		

		oRec = DoRig_Defaults_CA_2Obj(DoTes.Cd_DO, DoTes.Cd_CF, DoTes.Cd_CFDest, DoRig.Cd_AR, DoRig.Cd_CGConto)

		

		Replace 	Cd_CAVda 		With oRec.Cd_CAVda, ;

					Cd_CACda 		With oRec.Cd_CACda, ;

					Cd_CAFormula 	With oRec.Cd_CAFormula, ;

					CAPartenza 		With oRec.CAPartenza, ;

					CADurata 		With oRec.CADurata ;

					In DoRig

	EndScan



	oWa1 = SelectWA('DoRigSpesa')

	Calculate CNT() To nRC IN DoRigSpesa

	oProg.ReInit(nRC, 'Selezione dati di contabilità analitica in corso ... (' + Transform(nRC) + ')')



	Scan

		oProg.Advance(, Rtrim(DoRigSpesa.Descrizione))



		oRec = DoRig_Defaults_CA_2Obj(DoTes.Cd_DO, DoTes.Cd_CF, DoTes.Cd_CFDest, Null, DoRigSpesa.Cd_CGConto)



		Replace 	Cd_CAVda 		With oRec.Cd_CAVda, ;

					Cd_CACda 		With oRec.Cd_CACda, ;

					Cd_CAFormula 	With oRec.Cd_CAFormula, ;

					CAPartenza 		With oRec.CAPartenza, ;

					CADurata 		With oRec.CADurata ;

					In DoRigSpesa

	EndScan

	

	With ThisForm.PF.pgGenerale.PF

		With .PGRighe.Cnt.Grid

			.ColCd_CAVda.Refresh()

			.ColCd_CACda.Refresh()

			.ColCd_CAFormula.Refresh()

			.ColCAPartenza.Refresh()

			.ColCADurata.Refresh()

		EndWith



		With .PGPiede.Cnt.CntFattura.Grid

			.ColCd_CAVda.Refresh()

			.ColCd_CACda.Refresh()

			.ColCd_CAFormula.Refresh()

			.ColCAPartenza.Refresh()

			.ColCADurata.Refresh()

		EndWith

	EndWith

EndIf

ENDPROC

PROCEDURE Init

If !DoDefault()

	Return .F.

EndIf



This.AddProperty('AnagraficheObsolete', 0)

ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: fedi.PF.pgGenerale.txtNumeroDoc) ***
*** PROPERTIES ***
Comment = "ACAF840C-0DF7-4E73-B887-BF6A7D6F1904"

ControlSource = "dotes.numerodoc"

Format = ""

Top = 11

Width = 76

fktabledesc = Numeri disponibili

Name = "Field"


*** METHODS ***
PROCEDURE onvaluepick

LParameters nPickType, xValue4Value, oSelectedRec



Local cSuffix, cCd_CN, oDo, oCF



oDo				= ThisForm.PF.pgGenerale.txtCd_DO.Field.FKRecord

oCF				= ThisForm.PF.pgGenerale.txtCd_CF.Field.FKRecord

cCd_CN       	= Iif(oDo.FTE_AutoTipo = 1 And oCF.FTE_AutoTipo = 1 And !IsEmpty(oCF.FTE_Cd_CN), oCF.FTE_Cd_CN, oDo.Cd_CN)

cSuffix		 	= Nvl(RTrim(xSQLExec2Var('Select NumSuffix From CN Where Cd_Cn = ' + Format4Spt(cCd_CN))), '')

xValue4Value	= Rtrim(xValue4Value) + '/' + Rtrim(cSuffix)



Return DoDefault(nPickType, xValue4Value, oSelectedRec)





										

ENDPROC

PROCEDURE contextmenuproc

Lparameters nCBMId, xPar1, xPar2



Do Case

	Case nCBMId == CMM_ADD_ITEMS_TO_CONTEXT_MENU			

	

		Local oMenu

		Local lBrwSpc0

		

		DoDefault(nCBMId, xPar1, NEVL(xPar2, 0) + MB_EDIT_SRCFAST_NOBAR + MB_EDIT_SRCFULL_NOBAR + MB_EDIT_SRCFEDI_NOBAR) 	

		

		oMenu = xPar1

		

		If This.Enabled And !This.ReadOnly

			lBrwSpc0 =  PemStatus(This, 'BrwSpc0', 5) = .F. Or This.BrwSpc0

			

			oMenu.AddMenuBar('\-',,,MB_EDIT_SEP_SEARCH)

			oMenu.AddMenuBar(Thisform.TM_(,"DD1F255C-7613-4A20-B0A3-88293949E4A1", "Numeri \<disponibili..."), 	,'Key Alt+0, "F3"',	MB_EDIT_SRCHSPEC0	,,!lBrwSpc0,, "Images\MnuImages\Find1.bmp")

		EndIf

		Return .T.



	Case nCBMId == CMM_ADD_ITEMS_TO_EDIT_PAD		

		

		Local cPopupName, cOnSelCmd, cForm

		Local cBrwSpc0

		Local cKey

		

		DoDefault(nCBMId, xPar1, NEVL(xPar2, 0) + MB_EDIT_SRCFAST_NOBAR + MB_EDIT_SRCFULL_NOBAR + MB_EDIT_SRCFEDI_NOBAR) 	&& La classe base aggiunge le voci per la clipboard, le date ed i filtri... 

		

		cPopupName = xPar1

		cForm		  = Thisform.Name



		If This.Enabled And !This.ReadOnly

			cBrwSpc0 = Transform(PemStatus(This, 'BrwSpc0', 5) = .F. Or This.BrwSpc0) 

				

			Define Bar (MB_EDIT_SEP_SEARCH) Of (cPopupName) Prompt "\-"

			

			cOnSelCmd =  Sys(1272, This) + '.ContextMenuProc(' + Transform(CMM_PROCESS_CHOICE) + ', Bar())'



			DefineBar(MB_EDIT_SRCHSPEC0, cPopupName, [Prompt &cForm..TM_(,"0F3873FE-C71F-40C6-8E24-B6383D610C1F", "Codici \<disponibili...") Key Alt+0, "F3" Picture "Images\MnuImages\Find1.bmp" 	Skip For !&cBrwSpc0])

			On Selection 	Bar (MB_EDIT_SRCHSPEC0  ) Of (cPopupName) &cOnSelCmd

		EndIf

		Return .T.

		

	Case nCBMId == CMM_PROCESS_CHOICE					



		Local nChoiceId



		nChoiceId  = xPar1

		

		Do Case

			Case nChoiceId == MB_EDIT_SRCHSPEC0

				If This.Enabled And !This.ReadOnly



					Local lIsContabile, cCd_CN, dDataDoc, dValue, cOldDesc, cSuffix, oDo, oCF

					

					oDo		 	 = This.Parent.Parent.txtCd_DO.Field.FKRecord

					oCF			 = This.Parent.Parent.txtCd_CF.Field.FKRecord

					

					dValue		 = This.Parent.Parent.txtDataDoc.Field.Value

						

					cCd_CN       = Iif(oDo.FTE_AutoTipo = 1 And oCF.FTE_AutoTipo = 1 And !IsEmpty(oCF.FTE_Cd_CN), oCF.FTE_Cd_CN, oDo.Cd_CN)

					dDataDoc	 = Iif(Vartype(dValue) == 'T', TToD(dValue), dValue)

					cOldDesc	 = This.FKTableDesc

					

					oCN		 = xSQLExec2Obj('Select Tipo, NumSuffix From CN Where Cd_Cn = ' + Format4Spt(cCd_CN))

					

					**cSuffix		 = Nvl(RTrim(xSQLExec2Var('Select NumSuffix From CN Where Cd_Cn = ' + Format4Spt(cCd_CN))), '')

					cSuffix		 = Nvl(RTrim(oCN.NumSuffix), '')

					

					**lIsContabile = Iif(oApp.LicInfo.CG_Main Or CG_Export(), oDo.Contabile, .F.)				

					lIsContabile = Iif(oApp.LicInfo.CG_Main Or CG_Export(), oDo.Contabile Or oCN.Tipo='A', .F.)	

			

					This.FKSelect 		= "SELECT * FROM dbo.UnusedCodes_DoTes(" + Format4Spt(lIsContabile) + ", " + Format4Spt(dDataDoc) + ", " + Format4Spt(cCd_CN) + ") WHERE NumeroDoc = <TEXT>"

					This.FKTableDesc	= cOldDesc + Iif(!IsEmpty(cSuffix), ' /' + cSuffix, '')



					oSrchForm = RunFastSrcForm(ThisForm, This)

					This.AddProperty('BrwSpc0', Vartype(oSrchForm) == 'O')



					Iif(This.BrwSpc0, oSrchForm.Show(1), .T.)



					This.FKSelect 		= ''

					This.FKTableDesc	= cOldDesc

					

				EndIf 

				Return .T.

				

			Otherwise

				Return DoDefault(nCBMId, nChoiceId, MB_EDIT_SRCFAST_NOBAR + MB_EDIT_SRCFULL_NOBAR + MB_EDIT_SRCFEDI_NOBAR)

		EndCase

EndCase

ENDPROC

PROCEDURE KeyPress

LParameters nKeyCode, nShiftAltCtrl



If nKeyCode = -2 																&& F3 - Fast Search

	This.ContextMenuProc(CMM_PROCESS_CHOICE, MB_EDIT_SRCHSPEC0)	

	NoDefault

	Return .T.

EndIf



Return DoDefault(nKeyCode, nShiftAltCtrl)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Grid (BaseClass: grid, Parent: pgmoduli) ***
*** PROPERTIES ***
AllowAddNew = .T.

Height = 258

Left = 0

Top = 19

Width = 548

enableeditinshow = .T.

enablesingleprint = .T.

Name = "Grid"

ColRptDocName.Header1.Name = "Header1"

ColRptDocName.cmbRptDocName.Name = "cmbRptDocName"

ColRptDocName.StdText1.Name = "StdText1"

ColRptDocName.Name = "ColRptDocName"

ColNumeroCopie.Header1.Name = "Header1"

ColNumeroCopie.Text1.Name = "Text1"

ColNumeroCopie.Name = "ColNumeroCopie"

ColDevice.Header1.Name = "Header1"

ColDevice.CmbPrinterDevice.includeglobalprinters = .T.

ColDevice.CmbPrinterDevice.includelocalprinters = .T.

ColDevice.CmbPrinterDevice.includemailer = .T.

ColDevice.CmbPrinterDevice.includevirtualprinter = .T.

ColDevice.CmbPrinterDevice.includenotlocalprinters = .T.

ColDevice.CmbPrinterDevice.disablenotconfigured = .T.

ColDevice.CmbPrinterDevice.Name = "CmbPrinterDevice"

ColDevice.StdText1.Name = "StdText1"

ColDevice.Name = "ColDevice"

ColAnteprima.Header1.Name = "Header1"

ColAnteprima.Stdbtn1.Name = "Stdbtn1"

ColAnteprima.Name = "ColAnteprima"

ColEditOutput.Header1.Name = "Header1"

ColEditOutput.Stdbtn1.Name = "Stdbtn1"

ColEditOutput.Name = "ColEditOutput"

ColStampa.Header1.Name = "Header1"

ColStampa.Stdbtn1.Name = "Stdbtn1"

ColStampa.Name = "ColStampa"

ColLocalPrinter.Header1.Name = "Header1"

ColLocalPrinter.Stdcheck1.Alignment = 0

ColLocalPrinter.Stdcheck1.Name = "Stdcheck1"

ColLocalPrinter.Name = "ColLocalPrinter"

ColComputerName.Header1.Name = "Header1"

ColComputerName.StdText1.Name = "StdText1"

ColComputerName.Name = "ColComputerName"

colOfficial.Stdheader1.Name = "Stdheader1"

colOfficial.Chkbase1.Alignment = 2

colOfficial.Chkbase1.Enabled = .F.

colOfficial.Chkbase1.ReadOnly = .F.

colOfficial.Chkbase1.Name = "Chkbase1"

colOfficial.Enabled = .F.

colOfficial.Name = "colOfficial"


*** METHODS ***
PROCEDURE ongetid_dotes

Return DOTes.Id_DOTes



ENDPROC

PROCEDURE Init

If !DoDefault()

	Return .F.

EndIf



This.SetAll('DynamicBackColor', 'THIS.DynamicBackColor()')



Thisform.DE.DOReport.GridBounded = This







ENDPROC

PROCEDURE Refresh

** LPARAMETERS lForce

** If RecSignatureTest(This, 'DOTes', 'Cd_DO', 'Ts') OR lForce

** il requery viene forzato dal cambiamento di valore del campo txtCd_DO

If RecSignTest(This, Thisform.DE.DOTes)

	If !Thisform.SkipModuliRequery

**		Thisform.DE.DOReport.Requery('Cd_DO = ' + OldVal4Spt('DOTes', 'Cd_DO') + " AND (ComputerName IS NULL OR ComputerName =" + Format4SPT(oApp.ComputerName) + ")")

		Thisform.DE.DOReport.Requery('Cd_DO = ' + Format4Spt(DOTes.Cd_DO) + " AND (ComputerName IS NULL OR ComputerName =" + Format4SPT(oApp.ComputerName) + ")")

	Endif

	If Thisform.MODE != FEDIMODE_SHOW And Reccount('DOReport') = 0

		Thisform.DE.DOReport.AppendBlank()

		Tableupdate(2,.T., 'DOReport')

	Endif

Endif



Thisform.SkipModuliRequery = .F.



ENDPROC

PROCEDURE columnssortable

RETURN .F.

ENDPROC

PROCEDURE getbitmask

Return Thisform.DOBitMask

ENDPROC


*======================================================================

*** CLASS / OBJECT: Grid (BaseClass: grid, Parent: detail.PF.pgGenerale.txtMatricole) ***
*** PROPERTIES ***
ColumnCount = 1

Comment = "407A1A11-9591-4ECD-A043-C69494996DE0"

Anchor = 5

AllowAddNew = .T.

HeaderHeight = 0

Height = 133

Left = 1

Panel = 1

RecordSource = "DoRigMatricola"

RowHeight = 17

ScrollBars = 2

TabIndex = 24

Top = 16

Width = 167

ZOrderSet = 29

colnumname = Riga

Name = "Grid"

Stdcolumn1.Comment = "8986E3EB-9BA8-409E-947D-9691DE731D4D"

Stdcolumn1.FontName = "Courier New"

Stdcolumn1.FontSize = 8

Stdcolumn1.ControlSource = "Matricola"

Stdcolumn1.Width = 168

Stdcolumn1.Sparse = .F.

Stdcolumn1.Format = "!"

Stdcolumn1.Name = "ColMatricola"


*** METHODS ***
PROCEDURE onfocus

LParameters lEnter



Local nRec, nWA



If ThisForm.Parameters.ParentForm.Mode == FEDIMODE_SHOW

	Return

EndIf



If lEnter

	nWA = Select(0)

	Select DoRigMatricola

	nRec = RecNo()

	Count To nCount

	If nCount = 0

		ThisForm.cmdMatricolaAdd(This)

	EndIf

	Locate Record (nRec)

	This.Refresh()

	Select (nWA)

EndIf



With ThisForm.Toolbar

	.Buttons('MATRICOLAADD').Enabled = lEnter

	.Buttons('MATRICOLADEL').Enabled = lEnter

EndWith



ENDPROC

PROCEDURE rowinit

Lparameters nFromWhom



Local nRet



nRet = DoDefault(nFromWhom)

If Empty(Riga)

	Local nRec, nMax

	nRec = Recno()

	nMax = 0

	Calculate Max(Riga) To nMax

	Locate Record nRec

	Replace Riga With Nvl(nMax, 0) + 1

Endif



Return nRet



ENDPROC

PROCEDURE oncolumnheaderclick

**	Autogenerated code start -- don't touch

LPARAMETERS ocol

OnColClickMakeIndex(oCol)

**	Autogenerated code end   -- don't touch



ENDPROC


*======================================================================

*** CLASS / OBJECT: Grid (BaseClass: grid, Parent: detail.PF.pgGenerale.txtPackingList) ***
*** PROPERTIES ***
ColumnCount = 2

Comment = "80DFB310-AAAA-4B71-9C2B-88F9266E545B"

Anchor = 5

AllowAddNew = .T.

Height = 133

Left = 1

RecordSource = "DoRigPackList"

RowHeight = 17

ScrollBars = 2

TabIndex = 26

Top = 16

Width = 174

ZOrderSet = 23

colnumname = Riga

Name = "Grid"

Stdcolumn1.Comment = "7BA3A1A5-DEBF-4DAB-8408-4F9B9EC13536"

Stdcolumn1.FontName = "Segoe UI"

Stdcolumn1.FontSize = 8

Stdcolumn1.ControlSource = "DoRigPackList.PackListRef"

Stdcolumn1.Width = 116

Stdcolumn1.Sparse = .F.

Stdcolumn1.Name = "ColElemento"

Stdcolumn2.Comment = "21308B81-CE18-4CDB-9148-1BF2E499324B"

Stdcolumn2.FontName = "Segoe UI"

Stdcolumn2.FontSize = 8

Stdcolumn2.ControlSource = "DoRigPackList.Qta"

Stdcolumn2.Width = 34

Stdcolumn2.Name = "ColQta"


*** METHODS ***
PROCEDURE Init

DoDefault()



This.InitAutoSaveLayout()

ENDPROC

PROCEDURE When

** NB: Questo metodo è stato sovrascritto perchè nella conta dei record si vuol tenere conto del SET FILTER



Local nCount, nOldWA



If Empty(This.RecordSource) 

	This.HasFocus = .T.		&& Scatena l'HasFocus_Assign che gestisce le chiamate ad .OnFocus()

	Return .T.

EndIf



nOldWA = Select(0)



** Conto quanti record sono presenti (considerando anche il SET FILTER)

Select (This.RecordSource)

Count To nCount



Select (nOldWA)



If nCount = 0 

	If This.ReadOnly Or !This.AllowAddNew

		If PemStatus(Thisform, 'Title_bar', 5)

			Thisform.Title_bar.TabStop = IsNull(GetSiblingFocusableObject(This))

		EndIf

		Return .F.				&& Non voglio prenda il fuoco in modo che poi se passo in edit non lo abbia già: solo così nella When sucessiva è in grado di autoaggiungere un record...

	Else

		This.RowAppend()

	EndIf

EndIf

ENDPROC

PROCEDURE oncolumnheaderclick

**	Autogenerated code start -- don't touch

LPARAMETERS ocol

OnColClickMakeIndex(oCol)

**	Autogenerated code end   -- don't touch



ENDPROC

PROCEDURE onfocus

LParameters lEnter



With ThisForm.Toolbar

	.Buttons('MATRICOLAADD').Enabled = lEnter

	.Buttons('MATRICOLADEL').Enabled = lEnter

EndWith



ENDPROC

PROCEDURE rowinit

Lparameters nFromWhom



Replace Id_DoRig With xDefault(DORig.Id_DoRig, Recno('DORig')) IN DORIGPackList



Return DoDefault(nFromWhom)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Grid (BaseClass: grid, Parent: pgrighe) ***
*** PROPERTIES ***
ColumnCount = 37

Comment = "704B7788-38AF-4E47-A9BE-BC9CDD41A8D7"

Anchor = 15

Height = 256

Left = 0

Panel = 1

RecordSource = "DORig"

RowHeight = 17

TabIndex = 1

Top = 18

Width = 726

colnumname = riga

Name = "Grid"

Stdcolumn1.Comment = "2BC68F00-D944-4B2F-9874-9AE65B4681BE"

Stdcolumn1.FontName = "Segoe UI"

Stdcolumn1.FontSize = 8

Stdcolumn1.ColumnOrder = 25

Stdcolumn1.ControlSource = "DORig.Riga"

Stdcolumn1.Enabled = .F.

Stdcolumn1.Width = 36

Stdcolumn1.InputMask = "####"

Stdcolumn1.Name = "ColRiga"

Stdcolumn2.Comment = "15A67DB6-5E7E-4358-A377-A6F58262557A"

Stdcolumn2.FontName = "Segoe UI"

Stdcolumn2.FontSize = 8

Stdcolumn2.ColumnOrder = 4

Stdcolumn2.ControlSource = "DoRig.Cd_AR"

Stdcolumn2.Width = 68

Stdcolumn2.Name = "ColCd_AR"

Stdcolumn3.Comment = "6BA80602-D2A9-40AE-9F4E-EFAF395527BF"

Stdcolumn3.FontName = "Segoe UI"

Stdcolumn3.FontSize = 8

Stdcolumn3.ColumnOrder = 5

Stdcolumn3.ControlSource = "DORig.Descrizione"

Stdcolumn3.Width = 85

Stdcolumn3.Name = "ColDescrizione"

Stdcolumn4.Comment = "D6B994C8-CE3E-46BC-8306-B9927227053E"

Stdcolumn4.FontName = "Segoe UI"

Stdcolumn4.FontSize = 8

Stdcolumn4.ColumnOrder = 6

Stdcolumn4.ControlSource = "DORig.Cd_ARMisura"

Stdcolumn4.Width = 20

Stdcolumn4.Name = "ColCd_ARMisura"

Stdcolumn5.Comment = "E892FC24-DA82-419C-AD12-8BD461CFEA97"

Stdcolumn5.FontName = "Segoe UI"

Stdcolumn5.FontSize = 8

Stdcolumn5.ColumnOrder = 7

Stdcolumn5.ControlSource = "DORig.FattoreToUM1"

Stdcolumn5.Width = 60

Stdcolumn5.InputMask = "##,###.#####"

Stdcolumn5.Name = "ColFattoreToUM1"

Stdcolumn6.Comment = "72DF3A24-C509-44AC-9664-575F425A1853"

Stdcolumn6.FontName = "Segoe UI"

Stdcolumn6.FontSize = 8

Stdcolumn6.ColumnOrder = 8

Stdcolumn6.ControlSource = "DORig.Qta"

Stdcolumn6.Width = 68

Stdcolumn6.InputMask = "###,###,###.##"

Stdcolumn6.Name = "ColQta"

Stdcolumn7.Comment = "209810D6-14D9-4F5D-B3F3-EE2920BF1F5D"

Stdcolumn7.FontName = "Segoe UI"

Stdcolumn7.FontSize = 8

Stdcolumn7.ColumnOrder = 9

Stdcolumn7.ControlSource = "DORig.QtaEvadibile"

Stdcolumn7.Enabled = .F.

Stdcolumn7.Width = 96

Stdcolumn7.InputMask = "###,###,###.##"

Stdcolumn7.Name = "ColQtaEvadibile"

Stdcolumn8.Comment = "F274A8D2-F650-499C-95A3-A10AFF725393"

Stdcolumn8.FontName = "Segoe UI"

Stdcolumn8.FontSize = 8

Stdcolumn8.ColumnOrder = 15

Stdcolumn8.ControlSource = "DORig.PrezzoUnitarioV"

Stdcolumn8.Width = 110

Stdcolumn8.InputMask = "###,###,###.##"

Stdcolumn8.Name = "ColPrezzoUnitarioV"

Stdcolumn9.Comment = "09C49BED-273B-48F6-9C68-7F9646DA2E96"

Stdcolumn9.FontName = "Segoe UI"

Stdcolumn9.FontSize = 8

Stdcolumn9.ColumnOrder = 16

Stdcolumn9.ControlSource = "DORig.ScontoRiga"

Stdcolumn9.Width = 113

Stdcolumn9.Format = "!"

Stdcolumn9.Name = "ColScontoRiga"

Stdcolumn10.Comment = "61FE5584-C7A7-41B6-879A-A0C95C667A5F"

Stdcolumn10.FontName = "Segoe UI"

Stdcolumn10.FontSize = 8

Stdcolumn10.ColumnOrder = 17

Stdcolumn10.ControlSource = "DORig.PrezzoTotaleV"

Stdcolumn10.Enabled = .F.

Stdcolumn10.Width = 85

Stdcolumn10.InputMask = "###,###,###.##"

Stdcolumn10.Name = "ColPrezzoTotaleV"

Stdcolumn11.Comment = "25DBC927-3A8A-4FF2-94AA-FCFE8F6D5C64"

Stdcolumn11.FontName = "Segoe UI"

Stdcolumn11.FontSize = 8

Stdcolumn11.ColumnOrder = 18

Stdcolumn11.ControlSource = "DORig.Cd_Aliquota"

Stdcolumn11.Width = 28

Stdcolumn11.Format = "!"

Stdcolumn11.Name = "ColCd_Aliquota"

Stdcolumn12.Comment = "7E6CD6B2-0A47-4890-B059-2D99F91F8C93"

Stdcolumn12.FontName = "Segoe UI"

Stdcolumn12.FontSize = 8

Stdcolumn12.ColumnOrder = 20

Stdcolumn12.ControlSource = "DORig.Cd_CGConto"

Stdcolumn12.Width = 88

Stdcolumn12.Format = "!"

Stdcolumn12.Name = "ColCd_CGConto"

Stdcolumn13.Comment = "00E6593F-EE45-498F-BEE4-5A00DDA10891"

Stdcolumn13.FontName = "Segoe UI"

Stdcolumn13.FontSize = 8

Stdcolumn13.ColumnOrder = 22

Stdcolumn13.ControlSource = "DORig.ProvvigioneRiga_1"

Stdcolumn13.Width = 60

Stdcolumn13.Name = "ColProvvigioneRiga_1"

Stdcolumn14.Comment = "667B5437-F989-4D2F-A405-DC0F835F07D1"

Stdcolumn14.FontName = "Segoe UI"

Stdcolumn14.FontSize = 8

Stdcolumn14.ColumnOrder = 24

Stdcolumn14.ControlSource = "DORig.DataConsegna"

Stdcolumn14.Width = 68

Stdcolumn14.Name = "ColDataConsegna"

Stdcolumn15.Comment = "8E427FCA-8A0C-4257-9A82-E01791B26E29"

Stdcolumn15.FontName = "Segoe UI"

Stdcolumn15.FontSize = 8

Stdcolumn15.ColumnOrder = 23

Stdcolumn15.ControlSource = "DORig.ProvvigioneRiga_2"

Stdcolumn15.Width = 60

Stdcolumn15.Name = "ColProvvigioneRiga_2"

Stdcolumn16.Comment = "084D3019-4206-4658-8F4F-D5752DE8E19A"

Stdcolumn16.FontName = "Segoe UI"

Stdcolumn16.FontSize = 8

Stdcolumn16.ColumnOrder = 10

Stdcolumn16.ControlSource = "DoRig.Cd_MG_P"

Stdcolumn16.Width = 80

Stdcolumn16.Format = "!"

Stdcolumn16.Name = "ColCd_MG_P"

Stdcolumn17.Comment = "83B79A51-6098-4078-88C7-CA8F00863EE9"

Stdcolumn17.FontName = "Segoe UI"

Stdcolumn17.FontSize = 8

Stdcolumn17.ColumnOrder = 12

Stdcolumn17.ControlSource = "DoRig.Cd_MG_A"

Stdcolumn17.Width = 80

Stdcolumn17.Format = "!"

Stdcolumn17.Name = "ColCd_MG_A"

Stdcolumn18.Comment = "91D879B7-75A0-4C9B-AF80-E3A7789A0AEF"

Stdcolumn18.FontName = "Segoe UI"

Stdcolumn18.FontSize = 8

Stdcolumn18.ColumnOrder = 26

Stdcolumn18.ControlSource = "DORig.Cd_ARLotto"

Stdcolumn18.Width = 44

Stdcolumn18.Format = "!"

Stdcolumn18.Name = "ColCd_ARLotto"

Stdcolumn19.Comment = "8D3E21BC-4E34-414E-B551-FB231C012364"

Stdcolumn19.FontName = "Segoe UI"

Stdcolumn19.FontSize = 8

Stdcolumn19.ColumnOrder = 11

Stdcolumn19.ControlSource = "DoRig.Cd_MGUbicazione_P"

Stdcolumn19.Width = 130

Stdcolumn19.Format = "!"

Stdcolumn19.Name = "ColCd_MGUbicazione_P"

Stdcolumn20.Comment = "F7E2C284-E880-4535-986C-3DB36791D368"

Stdcolumn20.FontName = "Segoe UI"

Stdcolumn20.FontSize = 8

Stdcolumn20.ColumnOrder = 13

Stdcolumn20.ControlSource = "DoRig.Cd_MGUbicazione_A"

Stdcolumn20.Width = 130

Stdcolumn20.Format = "!"

Stdcolumn20.Name = "ColCd_MGUbicazione_A"

Stdcolumn21.Comment = "BFD15C96-4A6A-4567-AAFC-1B43B26FCE4B"

Stdcolumn21.FontName = "Segoe UI"

Stdcolumn21.FontSize = 8

Stdcolumn21.ColumnOrder = 14

Stdcolumn21.ControlSource = "DoRig.Cd_DOSottocommessa"

Stdcolumn21.Width = 78

Stdcolumn21.Format = "!"

Stdcolumn21.Name = "ColCd_DOSottoCommessa"

Stdcolumn22.Comment = "120D2183-005F-4276-95E4-A2AC4121FC5F"

Stdcolumn22.FontName = "Segoe UI"

Stdcolumn22.FontSize = 8

Stdcolumn22.ColumnOrder = 2

Stdcolumn22.Width = 19

Stdcolumn22.Resizable = .F.

Stdcolumn22.Sparse = .F.

Stdcolumn22.ToolTipText = "Dettaglio riga"

Stdcolumn22.Name = "ColDettagli"

Stdcolumn23.Comment = "143909E5-DFFA-4ED9-9789-1804E90294C9"

Stdcolumn23.FontName = "Segoe UI"

Stdcolumn23.FontSize = 8

Stdcolumn23.ColumnOrder = 1

Stdcolumn23.Width = 22

Stdcolumn23.Resizable = .F.

Stdcolumn23.Sparse = .F.

Stdcolumn23.DynamicCurrentControl = "IIF(IsEmpty(DoRig.Id_DoDb), 'btnNoDistinta', 'btnDistinta')"

Stdcolumn23.ToolTipText = "Distinta base particolare"

Stdcolumn23.Name = "ColDistinta"

Stdcolumn24.Comment = "407A69C0-2B91-4DEC-B24E-82F95EFBFBED"

Stdcolumn24.FontName = "Segoe UI"

Stdcolumn24.FontSize = 8

Stdcolumn24.ColumnOrder = 27

Stdcolumn24.ControlSource = "DoRIg.Cd_CAVda"

Stdcolumn24.Width = 81

Stdcolumn24.Format = "!"

Stdcolumn24.Name = "ColCd_CAVda"

Stdcolumn25.Comment = "14D9A2CD-56B5-4E79-A5B9-4A30F73DF97F"

Stdcolumn25.FontName = "Segoe UI"

Stdcolumn25.FontSize = 8

Stdcolumn25.ColumnOrder = 28

Stdcolumn25.ControlSource = "DoRIg.Cd_CACda"

Stdcolumn25.Width = 90

Stdcolumn25.Format = "!"

Stdcolumn25.Name = "ColCd_CACda"

Stdcolumn26.Comment = "1A4E0D04-8973-4D14-99C2-1A468F4E77C8"

Stdcolumn26.FontName = "Segoe UI"

Stdcolumn26.FontSize = 8

Stdcolumn26.ColumnOrder = 29

Stdcolumn26.ControlSource = "DoRIg.Cd_CAFormula"

Stdcolumn26.Width = 98

Stdcolumn26.Format = "!"

Stdcolumn26.Name = "ColCd_CAFormula"

Stdcolumn27.Comment = "FEBEC409-9395-40F6-8E53-10A71EC12B82"

Stdcolumn27.FontName = "Segoe UI"

Stdcolumn27.FontSize = 8

Stdcolumn27.ColumnOrder = 30

Stdcolumn27.Name = "ColCAPartenza"

Stdcolumn28.Comment = "DABAD2F7-7FB0-47D5-9F4F-792E195E82EF"

Stdcolumn28.FontName = "Segoe UI"

Stdcolumn28.FontSize = 8

Stdcolumn28.ColumnOrder = 31

Stdcolumn28.Name = "ColCADurata"

Stdcolumn29.Comment = "87932325-DC03-45C9-A6CE-3BF182007B62"

Stdcolumn29.FontName = "Segoe UI"

Stdcolumn29.FontSize = 8

Stdcolumn29.ColumnOrder = 32

Stdcolumn29.ControlSource = "DORig.RR_DataInizio"

Stdcolumn29.Width = 60

Stdcolumn29.Name = "ColRR_DataInizio"

Stdcolumn30.Comment = "38F363E7-BE0C-48C0-AF11-7FD15982E8D9"

Stdcolumn30.FontName = "Segoe UI"

Stdcolumn30.FontSize = 8

Stdcolumn30.ColumnOrder = 33

Stdcolumn30.ControlSource = "DORig.RR_DataFine"

Stdcolumn30.Width = 60

Stdcolumn30.Name = "ColRR_DataFine"

Stdcolumn31.Comment = "A8A7EE77-8B87-4E1A-845C-127CD5F42F1A"

Stdcolumn31.FontName = "Segoe UI"

Stdcolumn31.FontSize = 8

Stdcolumn31.ColumnOrder = 34

Stdcolumn31.ControlSource = "DORig.RR_Cd_CGConto"

Stdcolumn31.Width = 96

Stdcolumn31.Sparse = .F.

Stdcolumn31.Name = "ColRR_Cd_CGConto"

Stdcolumn32.Comment = "2F577FDC-7F76-4B19-A440-7CA6FB96AB33"

Stdcolumn32.FontName = "Segoe UI"

Stdcolumn32.FontSize = 8

Stdcolumn32.Alignment = 2

Stdcolumn32.ColumnOrder = 3

Stdcolumn32.ControlSource = "DoRig.TipoPC"

Stdcolumn32.Width = 16

Stdcolumn32.Name = "ColTipoPC"

Stdcolumn33.Comment = "43606D78-BBC6-41FC-AB0E-82AED4D12AA2"

Stdcolumn33.FontName = "Segoe UI"

Stdcolumn33.FontSize = 8

Stdcolumn33.ColumnOrder = 35

Stdcolumn33.ControlSource = "DORig.NoteRiga"

Stdcolumn33.CurrentControl = "StdEdit"

Stdcolumn33.Width = 32

Stdcolumn33.Sparse = .F.

Stdcolumn33.Name = "colNote"

Stdcolumn34.FontName = "Segoe UI"

Stdcolumn34.FontSize = 8

Stdcolumn34.Alignment = 2

Stdcolumn34.Bound = .F.

Stdcolumn34.ColumnOrder = 36

Stdcolumn34.ControlSource = "'Matricole'"

Stdcolumn34.Width = 60

Stdcolumn34.Sparse = .F.

Stdcolumn34.DynamicFontBold = "!IsEmpty(DoRig.Matricole)"

Stdcolumn34.DynamicCurrentControl = "Iif(IsEmpty(DoRig.Cd_AR) Or !ThisForm.PF.pgGenerale.txtCd_Do.Field.FKRecord.MtrEnabled, 'txtEmpty', 'txtMatricole')"

Stdcolumn34.InputMask = "XXXXXXXXX"

Stdcolumn34.Name = "colMatricole"

Stdcolumn35.Comment = "8915C3B6-EB85-4C65-B18F-5CA3CE4B2EDE"

Stdcolumn35.FontName = "Segoe UI"

Stdcolumn35.FontSize = 8

Stdcolumn35.ColumnOrder = 21

Stdcolumn35.ControlSource = "DORig.Cd_ReverseCharge"

Stdcolumn35.Width = 37

Stdcolumn35.Format = "!"

Stdcolumn35.Name = "ColCd_ReverseCharge"

Stdcolumn36.FontName = "Segoe UI"

Stdcolumn36.FontSize = 8

Stdcolumn36.ColumnOrder = 19

Stdcolumn36.ControlSource = "DORig.Cd_Aliquota_e"

Stdcolumn36.CurrentControl = "Stdtext1"

Stdcolumn36.Width = 28

Stdcolumn36.Format = "!"

Stdcolumn36.MousePointer = 15

Stdcolumn36.Name = "ColDoIntento"

Stdcolumn37.Comment = "F92C95B8-232F-4AE6-BB43-4A9EB78CBD06"

Stdcolumn37.FontName = "Segoe UI"

Stdcolumn37.FontSize = 8

Stdcolumn37.ControlSource = "DORig.Id_MGMov_Carico"

Stdcolumn37.Width = 120

Stdcolumn37.InputMask = "##,###,###,###"

Stdcolumn37.ForeColor = 0,0,255

Stdcolumn37.Name = "ColId_MGMov_Carico"


*** METHODS ***
PROCEDURE rowdelete

Lparameters lNoAppend



Local cMsg, cInfo

Local nSavedCheckFor





** Prima di cancellare controllo che la riga non sia stata evasa o non abbia evaso....

** Vado a controllare che la riga non abbia evaso altra riga

cInfo = This.Parent.GetEvadeInfo(DoRig.Id_DoRig_Evade)

cMsg  = "La riga evade il documento " + cInfo + CRLF + "Se essa viene cancellata il documento in questione verrà riaperto."

If !IsEmpty(cInfo) And !QuestionBox(RL_POWER_USER, cMsg, "cancellare questa riga")

    Return .F.

Endif



** In caso venga modificato il codice articolo vado a controllare che la riga non sia stata evasa da qualche altro documento

cInfo = This.Parent.GetEvasoDaInfo(DoRig.Id_DoRig)

cMsg  = "La riga è stata evasa dal/dai documenti " + CRLF + cInfo

If !IsEmpty(cInfo) And !QuestionBox(RL_POWER_USER, cMsg, "cancellare questa riga")

    Return  .F.

EndIf



nSavedCheckFor = This.ColCd_AR.StdText1.CheckFor

This.ColCd_AR.StdText1.CheckFor = 0



** Prima di cancellare la riga elimino l'eventuale distinta collegata

If !IsEmpty(DoRig.Id_DoDB)



    Select DoDB

    Locate For DoDB.Id_DoDB = DoRig.Id_DoDB

    If Found()



           ** tra le possibili modifiche fatte alla distinta ci possono essere

           ** inserimenti e aggiornamenti, ma anche cancellazioni, e questi record

           ** posso individuarli solo lavorando con Set Deleted Off

           

           Local cDeletedStatus

           cDeletedStatus = Set('Deleted')

           Set Deleted Off

           

           Delete

           TableUpdate(0, .F., 'DoDB')

           Select DoDBAttivita

           Scan For DoDBAttivita.Id_DoDB = DoRig.Id_DoDB

                 Select DoDBMateriale

                 Scan For DoDBMateriale.Id_DoDBAttivita = DoDBAttivita.Id_DoDBAttivita

                        Delete

                        TableUpdate(0, .F., 'DoDBMateriale')

                 EndScan      

                 Select DoDBAttivita                     

                 Delete

                 TableUpdate(0, .F., 'DoDBAttivita')                   

           EndScan

           

           Set Deleted &cDeletedStatus

    EndIf

    Select DoRig        

EndIf



** Prima di cancellare la riga elimino le eventuali righe di Packing list

Delete All In DoRigPackList

    

Thisform.oDoIntento.Wrk_Delete(Dorig.DoIntento)



** Proseguo cancellando la riga       

DoDefault(lNoAppend)



This.ColCd_AR.StdText1.CheckFor = nSavedCheckFor





ENDPROC

PROCEDURE layoutset

Lparameters cLayoutInfo

 

** Non ci sono impostazioni per la colonna ColTipoPC: è la prima volta che viene aggiunta, la posiziono con un default 

DoDefault(cLayoutInfo)

If Atc('ColTipoPC', cLayoutInfo) = 0

 	This.SetColumnOrder(This.ColTipoPC,  Max(This.ColCd_AR.ColumnOrder - 1, 1))

Endif



If Atc('ColNote', cLayoutInfo) = 0

	This.SetColumnOrder(This.ColNote,  Max(This.ColDescrizione.ColumnOrder + 1, 1))

Endif



ENDPROC

PROCEDURE rowinit

LParameters nFromWhom



Local cAlias



cAlias	 = This.RecordSource



If IsEmpty(&cAlias..CADurata)

	Replace Cambio With 1, CADurata With 1, Evadibile With .T. In (cAlias)

EndIf



** DOCIVATI

Replace ImportiIvati With DoTes.ImportiIvati In DoRig



Return DoDefault(nFromWhom)

ENDPROC

PROCEDURE columnssortable

Return .F.



ENDPROC

PROCEDURE onfocus

Lparameters lEnter



With Thisform.Toolbar

	.Buttons('ROWADD').Enabled 	= lEnter

	.Buttons('ROWDEL').Enabled 	= lEnter

	.Buttons('ROWINS').Enabled 	= lEnter

	.Buttons('ROWDOWN').Enabled	= lEnter

	.Buttons('ROWUP').Enabled 		= lEnter

	.Buttons('ROWCOPY').Enabled 	= lEnter

	.Buttons('ROWPASTE').Enabled	= lEnter

Endwith



ENDPROC

PROCEDURE Init

DoDefault()



ThisForm.DE.DORig.GridBounded = This



This.SetAll('DynamicBackColor', 'This.DynamicBackColor()')

This.SetAll('DynamicForeColor', 'This.DynamicForeColor()')

**This.ColNote.DynamicForeColor 	 = 'Iif(IsEmpty(DORig.NoteRiga), This.DynamicBackColor(), This.DynamicForeColor())'

This.ColDistinta.DynamicBackColor = ''

This.ColDistinta.DynamicForeColor = ''

This.ColDettagli.DynamicBackColor = ''

This.ColDettagli.DynamicForeColor = ''



** Cross Shape Only Edit (2nd Par)

Col_SetCross(This.ColRR_DataInizio.Text1, 	.T.)

Col_SetCross(This.ColRR_DataFine.Text1, 		.T.)

Col_SetCross(This.ColRR_Cd_CGConto.Text1, 	.T.)

Col_SetCross(This.ColCd_CAFormula.Text1, 		.T.)

Col_SetCross(This.ColCd_CACda.SpcCACda1, 		.T.)



** Imposto il controlsource in codice perché essendo complesso è più leggibile che dalle props

This.ColCAPartenza.ControlSource	= "CMonthYearIt(GoMonth(Thisform.CA_Datarif(), DoRig.CAPartenza))"

This.ColCADurata.ControlSource	= "CMonthYearIt(GoMonth(Thisform.CA_Datarif(), DoRig.CAPartenza + DoRig.CADurata - 1))"



** Collegamento al documento di carico per i resi

**	This.ColId_MGMov_Carico.ResetToDefault('DynamicForeColor')

**	This.ColId_MGMov_Carico.DynamicFontUnderline = '!IsEmpty(Id_MGMov_Carico)'

*This.ColId_MGMov_Carico.DynamicCurrentControl = 'stdtext1'

*This.ColId_MGMov_Carico.text1.Visible = .F.



ENDPROC

PROCEDURE Refresh

This.Parent.ModifyColumnsLook()



If RecSignTest(This, Thisform.DE.DOTes)

	Thisform.DE.DoRig.Requery('DORig.Id_DOTes = ' + OldVal4Spt('DOTes', 'Id_DOTes'))

	Thisform.DE.DoDB.Requery         ('1=0')	&&--> gestito con caricamento progressivo

	Thisform.DE.DoDBAttivita.Requery ('1=0')	&&--> gestito con caricamento progressivo

	Thisform.DE.DoDBMateriale.Requery('1=0')	&&--> gestito con caricamento progressivo	

Endif



DoDefault()

ENDPROC

PROCEDURE dynamicbackcolor

Return ;

	Iif(!Empty(DoRig.TipoRigaRif), 				  oApp.ColorInfoBK, ;

	Iif(DoRig.Id_DoRig = Thisform.ShowId_DoRig, oApp.ColorGridBackGreen, oApp.ColorWindow))

ENDPROC

PROCEDURE dynamicforecolor

Return Iif(IsEmpty(DoRig.Id_DoRig_Evade), oApp.ColorWindowText, oApp.ColorDecodedField)



ENDPROC

PROCEDURE Scrolled

LPARAMETERS nDirection



** Lo scrolling orizzontale ad un certo punto propone un fastidioso effetto di replica delle colonne e di header creando

** regalando una pessima visione delle grid. Siccome sembra soltanto un problema di paint, ma che non si sistema con draw(),

** Lockscreen e refresh, sembra bastare una semplice riassegnazione delle coordinate della grid per farla ridisegnare correttamente.



** ISSUE: al momento si verifica che nello scrolling H verso sx (tornando indietro) a volte le colonne sembrano ancorate a sx

** della grid ma basta insistere, sempre meglio che l'effetto precedente.



If nDirection > 3

	This.Top = This.Top

EndIf



ENDPROC

PROCEDURE ColCd_CGConto.Init

DoDefault()



This.Format 	= This.Spcconto1.Format 

This.InputMask = This.Spcconto1.InputMask 

ENDPROC


*======================================================================

*** CLASS / OBJECT: Grid (BaseClass: grid, Parent: pgpiede.CntFattura) ***
*** PROPERTIES ***
ColumnCount = 20

Comment = "A7BAFA9B-24EF-4020-A75D-536E33D91698"

Anchor = 15

AllowAddNew = .T.

Height = 88

Left = 1

Panel = 1

RecordSource = "DORigSpesa"

RowHeight = 19

TabIndex = 2

Top = 19

Width = 575

colnumname = riga

Name = "Grid"

Stdcolumn1.Comment = "F2E2696B-CBFF-4E5E-B453-8C20ADBD121A"

Stdcolumn1.FontName = "Segoe UI"

Stdcolumn1.FontSize = 8

Stdcolumn1.ControlSource = "DORigSpesa.Riga"

Stdcolumn1.Enabled = .F.

Stdcolumn1.Width = 13

Stdcolumn1.InputMask = "####"

Stdcolumn1.Name = "ColRiga"

Stdcolumn2.Comment = "1E6D7801-4B2F-46F7-B49D-F7EDE71F7BD0"

Stdcolumn2.FontName = "Segoe UI"

Stdcolumn2.FontSize = 8

Stdcolumn2.ControlSource = "DORigSpesa.TipoRigaSpesa"

Stdcolumn2.Width = 82

Stdcolumn2.Sparse = .F.

Stdcolumn2.Name = "ColTipoRigaSpesa"

Stdcolumn3.Comment = "31394283-8F7A-4E29-9CAB-5867CB8872D2"

Stdcolumn3.FontName = "Segoe UI"

Stdcolumn3.FontSize = 8

Stdcolumn3.ControlSource = "DORigSpesa.Descrizione"

Stdcolumn3.Width = 120

Stdcolumn3.Name = "ColDescrizione"

Stdcolumn4.Comment = "DDA23BB9-2FFE-4B68-AD11-121FFE8E0E0A"

Stdcolumn4.FontName = "Segoe UI"

Stdcolumn4.FontSize = 8

Stdcolumn4.ControlSource = "DORigSpesa.ImportoV"

Stdcolumn4.Width = 94

Stdcolumn4.Format = "Z"

Stdcolumn4.InputMask = "###,###,###.##"

Stdcolumn4.Name = "ColImportoV"

Stdcolumn5.Comment = "42B264B8-C4E0-4A13-90E6-0A3698BDB5C5"

Stdcolumn5.FontName = "Segoe UI"

Stdcolumn5.FontSize = 8

Stdcolumn5.ColumnOrder = 6

Stdcolumn5.ControlSource = "DORigSpesa.Cd_Aliquota"

Stdcolumn5.Width = 24

Stdcolumn5.Format = "!"

Stdcolumn5.Name = "ColCd_Aliquota"

Stdcolumn6.Comment = "F4F1DFAB-B6C4-4023-B8EE-38E746A3D927"

Stdcolumn6.FontName = "Segoe UI"

Stdcolumn6.FontSize = 8

Stdcolumn6.ColumnOrder = 8

Stdcolumn6.ControlSource = "DORigSpesa.Cd_CGConto"

Stdcolumn6.Width = 80

Stdcolumn6.Format = "!"

Stdcolumn6.Name = "ColCd_CGConto"

Stdcolumn7.Comment = "6BDF0720-8089-4BF6-A17E-6461B90A25A9"

Stdcolumn7.FontName = "Segoe UI"

Stdcolumn7.FontSize = 8

Stdcolumn7.ColumnOrder = 10

Stdcolumn7.ControlSource = "DoRigSpesa.ImportoEvadibileV"

Stdcolumn7.Width = 85

Stdcolumn7.Format = "Z"

Stdcolumn7.InputMask = "###,###,###.##"

Stdcolumn7.Name = "ColImportoEvadibileV"

Stdcolumn8.Comment = "1A653F56-D1EB-4DC4-BF2F-7E26F1BB56A2"

Stdcolumn8.FontName = "Segoe UI"

Stdcolumn8.FontSize = 8

Stdcolumn8.ColumnOrder = 11

Stdcolumn8.ControlSource = "DoRigSpesa.ImportoEvasoV"

Stdcolumn8.Width = 85

Stdcolumn8.Format = "Z"

Stdcolumn8.InputMask = "###,###,###.##"

Stdcolumn8.Name = "ColImportoEvasoV"

Stdcolumn9.Comment = "A5E70F63-5E06-459C-819A-C2D2FA501432"

Stdcolumn9.FontName = "Segoe UI"

Stdcolumn9.FontSize = 8

Stdcolumn9.ColumnOrder = 13

Stdcolumn9.ControlSource = "DoRigSpesa.Cd_CAVda"

Stdcolumn9.Format = "!"

Stdcolumn9.Name = "ColCd_CAVda"

Stdcolumn10.Comment = "832AE86E-53FD-4C3B-9879-A43CE80A6C44"

Stdcolumn10.FontName = "Segoe UI"

Stdcolumn10.FontSize = 8

Stdcolumn10.ColumnOrder = 14

Stdcolumn10.ControlSource = "DoRigSpesa.Cd_CACda"

Stdcolumn10.Width = 80

Stdcolumn10.Format = "!"

Stdcolumn10.Name = "ColCd_CACda"

Stdcolumn11.Comment = "67140840-9064-4E3D-8323-9391F55CCF77"

Stdcolumn11.FontName = "Segoe UI"

Stdcolumn11.FontSize = 8

Stdcolumn11.ColumnOrder = 15

Stdcolumn11.ControlSource = "DoRigSpesa.Cd_CAFormula"

Stdcolumn11.Format = "!"

Stdcolumn11.Name = "ColCd_CAformula"

Stdcolumn12.Comment = "E97FD8B4-43D3-450A-B052-95D7ECA22A7A"

Stdcolumn12.FontName = "Segoe UI"

Stdcolumn12.FontSize = 8

Stdcolumn12.ColumnOrder = 16

Stdcolumn12.Name = "ColCAPartenza"

Stdcolumn13.Comment = "6EAC6C4A-AA5F-4079-8374-7CB4BFFA341D"

Stdcolumn13.FontName = "Segoe UI"

Stdcolumn13.FontSize = 8

Stdcolumn13.ColumnOrder = 17

Stdcolumn13.Name = "ColCADurata"

Stdcolumn14.Comment = "C77AC00A-B498-480B-AA53-385A3F83B365"

Stdcolumn14.FontName = "Segoe UI"

Stdcolumn14.FontSize = 8

Stdcolumn14.ColumnOrder = 12

Stdcolumn14.ControlSource = "DoRigSpesa.Cd_SottoCommessa"

Stdcolumn14.Width = 81

Stdcolumn14.Name = "ColCd_SottoCommessa"

Stdcolumn15.Comment = "4CB4AE51-9810-41A1-B70E-AADB80C4D775"

Stdcolumn15.FontName = "Segoe UI"

Stdcolumn15.FontSize = 8

Stdcolumn15.ColumnOrder = 18

Stdcolumn15.ControlSource = "DoRigSpesa.RigaSpesa_Evasa"

Stdcolumn15.CurrentControl = "Stdedit1"

Stdcolumn15.Width = 87

Stdcolumn15.Sparse = .F.

Stdcolumn15.Name = "ColRigaSpesa_Evasa"

Stdcolumn16.Comment = "203B0772-C844-4779-9B37-DD7F9A16D7D5"

Stdcolumn16.FontName = "Segoe UI"

Stdcolumn16.FontSize = 8

Stdcolumn16.ColumnOrder = 5

Stdcolumn16.ControlSource = "DoRigSpesa.Perc"

Stdcolumn16.Width = 48

Stdcolumn16.Format = "Z"

Stdcolumn16.InputMask = "999.99"

Stdcolumn16.Name = "ColPerc"

Stdcolumn17.Comment = "11185EED-8B74-4A76-87A7-3497353B39D0"

Stdcolumn17.FontName = "Segoe UI"

Stdcolumn17.FontSize = 8

Stdcolumn17.ColumnOrder = 9

Stdcolumn17.ControlSource = "DORigSpesa.Cd_ReverseCharge"

Stdcolumn17.Width = 35

Stdcolumn17.Format = "!"

Stdcolumn17.Name = "ColCd_ReverseCharge"

Stdcolumn18.FontName = "Segoe UI"

Stdcolumn18.FontSize = 8

Stdcolumn18.ColumnOrder = 7

Stdcolumn18.ControlSource = "DoRigSpesa.Cd_Aliquota_e"

Stdcolumn18.Width = 24

Stdcolumn18.Format = "!"

Stdcolumn18.MousePointer = 15

Stdcolumn18.Name = "ColDoIntento"

Stdcolumn19.FontName = "Segoe UI"

Stdcolumn19.FontSize = 8

Stdcolumn19.ControlSource = "DoRigSpesa.DataInizioComp"

Stdcolumn19.Width = 95

Stdcolumn19.Name = "ColDataInizioComp"

Stdcolumn20.FontName = "Segoe UI"

Stdcolumn20.FontSize = 8

Stdcolumn20.ControlSource = "DoRigSpesa.DataFineComp"

Stdcolumn20.Width = 89

Stdcolumn20.Name = "ColDataFineComp"


*** METHODS ***
PROCEDURE Scrolled

LPARAMETERS nDirection



** Vedi commento in grid righe



If nDirection > 3

	This.Top = This.Top

EndIf



ENDPROC

PROCEDURE dynamicbackcolor

Return Iif(DoRigSpesa.Id_DORigSpesa = Thisform.ShowId_DORigSpesa, oApp.ColorGridBackGreen, oApp.ColorWindow)



ENDPROC

PROCEDURE oncolumnheaderclick

**	Autogenerated code start -- don't touch

LPARAMETERS ocol

OnColClickMakeIndex(oCol)

**	Autogenerated code end   -- don't touch



ENDPROC

PROCEDURE columnssortable

Return .F.

ENDPROC

PROCEDURE onfocus

LPARAMETERS lEnter



WITH THISFORM.TOOLBAR

	.BUTTONS('ROWADD').ENABLED 	= lEnter

	.BUTTONS('ROWDEL').ENABLED 	= lEnter

	.BUTTONS('ROWINS').ENABLED 	= lEnter

	.BUTTONS('ROWDOWN').ENABLED	= lEnter

	.BUTTONS('ROWUP').ENABLED 		= lEnter

	.BUTTONS('ROWCOPY').ENABLED 	= lEnter

	.BUTTONS('ROWPASTE').ENABLED 	= lEnter

ENDWITH



ENDPROC

PROCEDURE Refresh

This.Parent.Parent.ModifyColumnsLook()



If RecSignTest(This, Thisform.DE.DOTes)

	Thisform.DE.DORigSpesa.Requery('DORigSpesa.Id_DOTes = ' + OldVal4Spt('DOTes', 'Id_DOTes'))	

EndIf 



ENDPROC

PROCEDURE Init

Dodefault()



This.SetAll('DynamicBackColor', 'THIS.DynamicBackColor()')

This.SetAll('DynamicForeColor', 'THIS.DynamicForeColor()')



** Le situazioni in cui non voglio dare la possibilità di scrivere faccio comparire uno shape diagonal cross

Col_SetCross(This.ColPerc.Text1)

Col_SetCross(This.ColImportoV.Text1)

Col_SetCross(This.ColImportoEvadibileV.Text1)

Col_SetCross(This.ColImportoEvasoV.Text1, .T., "(DORigSpesa.TipoRigaSpesa != 'T' Or DORigSpesa.Perc = 0)")



** Imposto il controlsource in codice perché essendo complesso è più leggibile che dalle props

This.ColCAPartenza.ControlSource	= "CMonthYearIt(GoMonth(Thisform.CA_Datarif(), DoRigSpesa.CAPartenza))"

This.ColCADurata.ControlSource	= "CMonthYearIt(GoMonth(Thisform.CA_Datarif(), DoRigSpesa.CAPartenza + DoRigSpesa.CADurata - 1))"



Thisform.DE.DORigSpesa.GridBounded = This







ENDPROC

PROCEDURE dynamicforecolor

Return Iif(IsEmpty(DoRigSpesa.Id_DoRigSpesa_Evade), oApp.ColorWindowText, oApp.ColorDecodedField)



ENDPROC

PROCEDURE rowinit

Lparameters nFromWhom



Local cAlias, cAlias_DO



cAlias	 = This.RecordSource

cAlias_DO = ThisForm.PF.pgGenerale.txtCd_DO.Field.FKAlias



** DOCIVATI **

Replace ImportiIvati With DoTes.ImportiIvati In DoRigSpesa



If IsEmpty(&cAlias..TipoRigaSpesa)

	This.colTipoRigaSpesa.cmbTipoSpesa1.SetValue('V')

EndIf



If IsEmpty(&cAlias..CADurata)

	This.colCADurata.Text1.SetValue(1)

EndIf



If !IsEmpty(DoTes.Cd_DOSottoCommessa)

	This.colCd_SottoCommessa.Text1.SetValue(DoTes.Cd_DOSottoCommessa)

EndIf  



**This.ColDataInizioComp.text1.SetValue(xSqlExec2Var("Select dbo.afn_dt_FirstDayOfMonth("+Format4Spt(Gomonth(DoTes.DataDoc, DoRigSpesa.CAPartenza))+")"))

**This.ColDataFineComp.text1.SetValue(xSqlExec2Var("Select dbo.afn_dt_FirstDayOfMonth("+Format4Spt(Gomonth(DoRigSpesa.DataInizioComp, DoRigSpesa.CADurata))+")"))





** Default per RR

**	If &cAlias_DO..RR_Enabled

**		Local oRRConfig



**		oRRConfig = RR_GetConfig(&cAlias_DO..Cd_RRConfig, DOTes.DataRif)

**		If !IsNull(oRRConfig)

**			Replace RR_Cd_CGConto With oRRConfig.RR_Cd_CGConto In (cAlias)



**			If !Empty(RR_ValidateFields(DOTes.DataRif, oRRConfig.RR_DataInizio, oRRConfig.RR_DataFine))

**				Replace ;

**					RR_DataInizio With oRRConfig.RR_DataInizio, ;

**					RR_DataFine   With oRRConfig.RR_DataFine ;

**				In (cAlias)

**			EndIf

**		EndIf

**	EndIf



This.parent.parent.Setdorigspesa_defaults_DI('DEF')

This.parent.parent.Setdorigspesa_Defaults_IVA()



Return DoDefault(nFromWhom)



ENDPROC


*======================================================================

*** CLASS / OBJECT: pgevasioni (BaseClass: container, Parent: ) ***
*** PROPERTIES ***
Width = 708

Height = 376

Name = "pgevasioni"


*** METHODS ***
PROCEDURE Refresh

Lparameters lForce



With Thisform.PF.pgGenerale.PF

	If .pgRighe.ControlCount = 0

		Thisform.PF.pgGenerale.PF.DynamicPageInit(.pgRighe)

	Endif

	.pgRighe.Cnt.Grid.Refresh()

Endwith



**	If xSqlExec2Var("If Exists(Select * from DODOPrel Where Cd_DO_Prelevabile = '" + DOTes.Cd_DO + "') Select 1 Else Select 0") = 0	&& non possono essere documenti evadenti

**		ObjMov(This.cntLV, 3000)							&& nascondo il primo LV

**		ObjDim(This.cntLV1, , This.cntLV.Top)			&& allargo il secondo LV verso l'alto

**	Else

**		ObjMov(This.cntLV, 0)								&& ripristo il left del primo LV

**		ObjDim(This.cntLV1, , This.Height/2 + 2)		&& ripristo il top del secondo LV

**	EndIf 



**	If xSqlExec2Var("If Exists(Select * From DODOPrel Where Cd_DO = '" + DOTes.Cd_DO + "') Select 1 Else Select 0") = 0	&& non possono essere documenti evasi

**		ObjMov(This.cntLV1, 3000)							&& nascondo il secondo LV

**		ObjDim(This.cntLV, , , , This.cntLV1.Bottom)	&& allargo il primo LV verso il basso

**	Else

**		ObjMov(This.cntLV1, 0)								&& ripristo il left del secondo LV

**		ObjDim(This.cntLV,,,, This.Height/2 - 2)		&& ripristo l'height del primo LV	

**	EndIf 



**	This.cntLV.Refresh()

**	This.cntLV1.Refresh()



ENDPROC


*======================================================================

*** CLASS / OBJECT: LV (BaseClass: olecontrol, Parent: pgevasioni.cntLV) ***
*** PROPERTIES ***
Top = 20

Left = 1

Height = 164

Width = 705

Anchor = 15

Name = "LV"


*** METHODS ***
PROCEDURE Init

This.AddProperty('Mode', 'EVADENTI')

Return DoDefault()

ENDPROC


*======================================================================

*** CLASS / OBJECT: LV (BaseClass: olecontrol, Parent: pgevasioni.cntLV1) ***
*** PROPERTIES ***
Top = 20

Left = 1

Height = 167

Width = 705

Anchor = 15

Name = "LV"


*** METHODS ***
PROCEDURE Init

This.AddProperty('Mode', 'EVASI')

Return DoDefault()

ENDPROC


*======================================================================

*** CLASS / OBJECT: LV (BaseClass: container, Parent: detail.PF.pgFEPA) ***
*** PROPERTIES ***
Comment = "3386FBEF-D244-4B29-A21B-DDAB695DD19D"

Anchor = 4

Top = 186

Left = 3

Width = 100

Height = 268

TabIndex = 4

ZOrderSet = 5

Name = "LV"

_sep.Name = "_sep"

ListItems.Name = "ListItems"

Timer.Name = "Timer"

btnDown.Name = "btnDown"

btnUp.Name = "btnUp"

_imagelist1.Top = 60

_imagelist1.Left = 36

_imagelist1.Height = 50

_imagelist1.Width = 50

_imagelist1.Name = "_imagelist1"


*** METHODS ***
PROCEDURE Init

DoDefault()



This.ListItems.Add(, '1', 'ORDINE' 				+ Chr(13) + '(2.1.2)')

This.ListItems.Add(, '2', 'CONTRATTO' 			+ Chr(13) + '(2.1.3)')

This.ListItems.Add(, '3', 'CONVENZIONE'		+ Chr(13) + '(2.1.4)')

This.ListItems.Add(, '4', 'RICEZIONE' 			+ Chr(13) + '(2.1.5)')

This.ListItems.Add(, '5', 'FT. COLLEGATE'		+ Chr(13) + '(2.1.6)')

This.ListItems.Add(, '6', 'DDT' 					+ Chr(13) + '(2.1.8)')



ENDPROC

PROCEDURE itemclick

*** ActiveX Control Event ***

LPARAMETERS item



DODEFAULT(item)



Local cKey, nIdx



cKey = Upper(Item.Key)

nIdx = Val(Item.Key)



This.Parent.PFR.ActivePage = nIdx

This.Parent.PFR.CurrentPage.Refresh()





ENDPROC


*======================================================================

*** CLASS / OBJECT: pgevasioni_lv (BaseClass: olecontrol, Parent: ) ***
*** PROPERTIES ***
Height = 107

Width = 364

Name = "pgevasioni_lv"


*** METHODS ***
PROCEDURE changeitemstate

Lparameters oItem 



Local nState, nNewIndex, nId_DORig

Local oNextItem, oNewItem

Local cStmt, cPicSep, cPicSepPrzUn, cVLAlias



nState = LV_GetStateImage(This.HWnd, oItem.Index)



oItem.Selected = .T.



If nState = 2	&& Node is expanded



	Do While .T. 

		If oItem.Index < This.ListItems.Count 

			oNextItem = This.ListItems(oItem.Index + 1)

		Else

			oNextItem = .F.

		EndIf 	

		

		** Cancello tutti i nodi che hanno l'indentazione maggiore del nodo corrente		

		If Vartype(oNextItem) = 'O' And This.GetItemIndent(oItem.Index) < This.GetItemIndent(oNextItem.Index) 

			This.ListItems.Remove(oNextItem.Index)

		Else

			Exit

		EndIf

	EndDo 



	LV_SetStateImage(This.HWnd, oItem.Index, 1)

EndIf 



If nState = 1 && Node is collapsed



	nId_DORig = Val(Substr(oItem.Key, 9))

	

	If This.Mode = 'EVASI'

	

		Text To cStmt Textmerge NoShow

			Select 

				R2.Id_DOTes, R2.Id_DORig, R2.Cd_DO, R2.NumeroDoc, R2.DataDoc, R2.Riga, R2.Cd_AR, R2.Descrizione, R2.Cd_ARMisura, R2.Qta, R2.QtaEvasa, R2.QtaEvadibile, R2.Cd_VL, R2.PrezzoUnitarioV, R2.ScontoRiga, R2.PrezzoTotaleV, R2.Cd_Aliquota, R2.TipoRigaRif, 

				R1.Cd_ARMisura As Cd_ARMisura1,

				R2.Id_DORig_Evade,

				Convert(bit, Case When R2.Id_DORig_Evade Is Null Then 0 Else 1 End) As Expandable

			From 

				DoRig R1

				Left Join DoRig R2 On R1.Id_DORig_Evade = R2.Id_DoRig

			Where 

				R1.Id_DORig = <<FormatI4Spt(nId_DoRig)>>

			Order By

				Riga		

		EndText 

		

	Else

	

		Text To cStmt Textmerge NoShow

			Select 

				Id_DOTes, Id_DORig, Cd_DO, NumeroDoc, DataDoc, Riga, Cd_AR, Descrizione, Cd_ARMisura, Qta, QtaEvasa, QtaEvadibile, Cd_VL, PrezzoUnitarioV, ScontoRiga, PrezzoTotaleV, Cd_Aliquota, TipoRigaRif,

				Convert(bit, Case When Exists(Select * From DoRig R2 Where R2.Id_DORig_Evade = R1.Id_DORig) Then 1 Else 0 End) As Expandable

			From 

				DoRig R1

			Where

				 Id_DORig In (Select Id_DORig From DoRig R2 Where R2.Id_DORig_Evade = <<FormatI4Spt(nId_DoRig)>>)	-- Al click su una riga per espanderla

			Order By

				Riga

		EndText 

		

	EndIf 

	xSqlExec(cStmt, 'Righe2')



	** Picture della valuta

	With Thisform.PF.pgGenerale

		cVLAlias = .txtCd_VL.Field.FKAlias

		If Empty(cVLAlias)

			.txtCd_VL.Field.Refresh()

			cVLAlias = .txtCd_VL.Field.FKAlias

		Endif

		cPicSep		 = Eval(cVLAlias + '.PicSep'     )

		cPicSepPrzUn = Eval(cVLAlias + '.PicSepPrzUn')

	EndWith 

	

	** Trovo l'item corrispondente alla prima riga dell'albero

	Local oItemP

	oItemP = oItem

	Do While .T.

		If This.GetItemIndent(oItemP) = 0

			Exit

		EndIf 

		oItemP = This.ListItems(oItemP.Index-1)

	EndDo 

	

	** Aggiungo le righe figlie del nodo corrente

	nNewIndex = oItem.Index + 1

	Scan

		** Nella property .KEY metto il valore di ID_DORig seguito da "__" e Index della riga padre

		oNewItem = This.ListItems.Add(nNewIndex, 'Id_DoRig' + Tran(Righe2.Id_DoRig) + '__' + Tran(oItemP.Index), Righe2.Cd_DO + Righe2.NumeroDoc, , 'DOCUMENT' )

		

		If Righe2.Expandable

			LV_SetStateImage(This.HWnd, oNewItem.Index, 1)

		EndIf 

		This.SetItemIndent(nNewIndex, This.GetItemIndent(oItem.Index)+1)



		oNewItem.SubItems(1) = 'del ' + Dtoc(Righe2.DataDoc)

		oNewItem.SubItems(2) = Transform(Righe2.Riga)

		oNewItem.SubItems(3) = Ltrim(Tran(Righe2.Qta, oApp.Preferenza.PicSepQta))

		oNewItem.SubItems(4) = Rtrim(Nvl(Righe2.Cd_ArMisura, ''))



		If This.Mode = 'EVASI' && And (Righe2.Qta != Righe2.QtaEvasa And !IsEmpty(Righe2.Id_DoRig_Evade)

			

			If Righe2.QtaEvasa != 0

				oNewItem.SubItems(5) = Iif(!IsEmpty(Righe2.Cd_ARMisura1) And Righe2.Cd_ARMisura != Righe2.Cd_ARMisura1, '(' + Rtrim(Righe2.Cd_ARMisura1) + ') ', '') + Ltrim(Tran(Righe2.QtaEvasa, oApp.Preferenza.PicSepQta))

			

				If This.ColumnHeaders(6).Width = 0 And (Righe2.Cd_ARMisura != Righe2.Cd_ARMisura1 Or (Righe2.QtaEvasa != 0 And Righe2.Qta != Righe2.QtaEvasa))

					This.ColumnHeaders(6).Width = 65

				EndIf 

			EndIf 

			

		Else

			oNewItem.SubItems(5) = ''

		EndIf 	



		oNewItem.SubItems(6) = Ltrim(Tran(Righe2.QtaEvadibile, oApp.Preferenza.PicSepQta))



		If Righe2.PrezzoUnitarioV != Val(oItemP.SubItems(8))	&& visualizzo i prezzi solo se diversi dalla riga padre...

			oNewItem.SubItems(7)  = Rtrim(Righe2.Cd_VL)

			oNewItem.SubItems(8)  = Ltrim(Tran(Righe2.PrezzoUnitarioV, cPicSepPrzUn))

			oNewItem.SubItems(9)  = Rtrim(Righe2.ScontoRiga)

			oNewItem.SubItems(10) = Ltrim(Tran(Righe2.PrezzoTotaleV, cPicSep))

			oNewItem.SubItems(11) = Nvl(Righe2.Cd_Aliquota, '')

		EndIf 

		

		If Evaluate(Evl(Substr(oApp.oUser.GetDoWhere('Righe2.Cd_DO', .T.), 5), '1=1'))

			oNewItem.SubItems(12) = TX_(, "C23A1D67-9A52-4BCC-B39B-C292B971EF6D", 'Modifica')

		EndIf 



		nNewIndex = nNewIndex + 1

	EndScan 



	Use In Righe2





	LV_SetStateImage(This.HWnd, oItem.Index, 2)

EndIf 



ENDPROC

PROCEDURE onsubitemclick

Lparameters oSubItem, nShift



Local oForm

Local nId_DOTes, nId_DORig

Local cInitialWhere



** Colonna <Vedi>

If oSubItem.SubItem = 12 And  This.ListItems(oSubItem.Item+1).SubItems(oSubItem.SubItem) != ''



	nId_DORig = Val(Substr(This.ListItems(oSubItem.Item+1).Key, 9))

	nId_DOTes = xSqlExec2Var('Select Id_DOTes From DoRig Where Id_DORig = ' + Transform(nId_DORig))



	cInitialWhere = 'DoTes.Id_DoTes = ' + FormatI4Spt(nId_DOTes )

	oForm			  = RunFediDoc(nId_DOTes, nId_DORig ,, Iif(Thisform.WindowType = 0, .F., Thisform),, cInitialWhere)

	If Vartype(oForm) = 'O'

		*oForm.NewObject('Fedi_EvtHook' + Sys(2015), 'Fedi_EvtHook', 'Progs\OWCTools.fxp', '', This)

		If oForm.DE.MainCursor.RecCount() = 1

			oForm.cmdPgGenerale()

			If !IsEmpty(nId_DORig)

				oForm.ShowId_DoRig = nId_DORig

				oForm.PF.pgGenerale.PF.ActivePage = oForm.PF.pgGenerale.PF.pgRighe.PageOrder

				oForm.PF.pgGenerale.PF.pgRighe.cnt.Grid.Refresh()

			EndIf

		EndIf

		oForm.Show()

	EndIf



EndIf 

ENDPROC

PROCEDURE onsubitemrightclick

Lparameters oSubItem, nShift

ENDPROC

PROCEDURE refreshdata

Local cStmt

Local nId_DOTes



nId_DOTes = DOTes.Id_DOTes



If This.Mode = 'EVASI'



	Text To cStmt TextMerge NoShow



		Select 

			R1.Id_DOTes, R1.Id_DORig, R1.Cd_DO, R1.Riga, R1.Cd_AR, R1.Descrizione, R1.Cd_ArMisura, R1.Qta, R1.QtaEvasa, R1.QtaEvadibile, R1.Cd_VL, R1.PrezzoUnitarioV, R1.ScontoRiga, R1.PrezzoTotaleV, R1.Cd_Aliquota, R1.TipoRigaRif,

			R2.Cd_ARMisura As Cd_ARMisura1,

			R1.Id_DORig_Evade, 

			Convert(bit, Case When R1.Id_DORig_Evade Is Null Then 0 Else 1 End) As Expandable

		From 

			DoRig R1

			Left Join DoRig R2 On R1.Id_DORig_Evade = R2.Id_DoRig

		Where

			R1.Id_DOTes = <<FormatI4Spt(nId_DOTes)>>	-- Caricamento delle righe del doc corrente

		Order By

			Riga



	EndText 



Else



	Text To cStmt TextMerge NoShow



		Select 

			Id_DOTes, Id_DORig, Cd_DO, Riga, Cd_AR, Descrizione, Cd_ArMisura, Qta, QtaEvasa, QtaEvadibile, Cd_VL, PrezzoUnitarioV, ScontoRiga, PrezzoTotaleV, Cd_Aliquota, TipoRigaRif,

			Convert(bit, Case When Exists(Select * From DoRig R2 Where R2.Id_DORig_Evade = R1.Id_DORig) Then 1 Else 0 End) As Expandable

		From 

			DoRig R1

		Where

			 Id_DOTes =  <<FormatI4Spt(nId_DOTes)>>	-- Caricamento delle righe del doc corrente

		Order By

			Riga



	EndText 



EndIf 



xSqlExec(cStmt, 'Righe')

ENDPROC

PROCEDURE customdraw_postsubitemdraw

Lparameters nItem, hSubItem, hDC, lParam



If This.hOldFont != 0

	SelectObject(hDC, This.hOldFont)

	This.hOldFont = 0

EndIf

		

ENDPROC

PROCEDURE Refresh

This.RefreshData()

This.Load()



ENDPROC

PROCEDURE Click

Local oItem, oSubItem

Local nButton, nShift, nX, nY

Local lOnIcon



nButton	= This.MouseUp_Button

nShift	= This.MouseUp_Shift

nX			= This.MouseUp_X

nY			= This.MouseUp_Y



oItem 	= This.xHitTest(nX, nY)

oSubItem = This.SubItemHitTest(nX, nY)



Do Case 

	Case oSubItem.Flags = 1	&& NoWhere

		Return

	

	Case oSubItem.Flags = 2 Or oSubItem.Flags = 4	&& OnItemIcon + OnItemLabel



		If oSubItem.SubItem = 0			



			lOnIcon = (oSubItem.Flags = 2)

		

			If nButton = 1  && Left Button

				This.OnClick     (oItem, nShift, lOnIcon)

				Return

			EndIf



			If nButton = 2 	&& Right Button

				This.OnRightClick(oItem, nShift, , , lOnIcon)

			EndIf

		

		Else



			If nButton = 1  && Left Button

				This.OnSubItemClick     (oSubItem, nShift)

				Return

			EndIf



			If nButton = 2 	&& Right Button

				This.OnSubItemRightClick(oSubItem, nShift)

			EndIf

		

		EndIf 



	Case oSubItem.Flags = 8	&& OnItemStateIcon 

		

		If nButton = 1

			This.ChangeItemState(oItem)

		EndIf 

			

EndCase 





ENDPROC

PROCEDURE Init

Local oIL1, oIL2



DoDefault()



** Add the ListView ColumnHeaders

This.ColumnHeaders.Add( , , Tx_(, "8F55E725-AD87-46DC-A014-9FCF2670E7A1", "Articolo"), 			130)

This.ColumnHeaders.Add( , , Tx_(, "6A2C2F7A-E1B4-4BC5-82B4-E1A0EBE72D8F", "Descrizione"), 		180)

This.ColumnHeaders.Add( , , Tx_(, "F2A28523-5830-47DA-B9A4-7B69FA17577F", "Riga"), 				 20, 1)

This.ColumnHeaders.Add( , , Tx_(, "A295D601-24C3-471B-B03F-DF5657161E92", "Quantità"),	 		 60, 1)

This.ColumnHeaders.Add( , , Tx_(, "51409B48-9322-402B-B6A7-350652A14B3A", "UM"), 		 		 	 20)

This.ColumnHeaders.Add( , , Tx_(, "4DE5AE11-90E7-4F13-9B13-ED66B43C82E6", "Q.tà evasa"), 	 	  0, 1)		&& solo per EVASI

This.ColumnHeaders.Add( , , Tx_(, "416FF295-64BF-4547-AA49-DFA2A2A4DF0D", "Q.tà evadibile"), 	  0, 1)

This.ColumnHeaders.Add( , , Tx_(, "C389218D-16EC-4C48-91DA-92C606E3FC87", "VL"), 		 		 	 15)

This.ColumnHeaders.Add( , , Tx_(, "10155D3C-F932-4079-AFFB-CACDC5595ADD", "Prezzo un."), 		 60, 1)

This.ColumnHeaders.Add( , , Tx_(, "F1A89689-A44E-49FD-98A6-7CA479243647", "Sconto"), 			 	 40)

This.ColumnHeaders.Add( , , Tx_(, "082A0355-7900-4349-9433-A8AC9A1CE9C0", "Prezzo totale"), 	 60, 1)

This.ColumnHeaders.Add( , , Tx_(, "8B4A4B3B-2F81-40C6-81A0-C6255F430799", "Iva"),  				 20)

This.ColumnHeaders.Add( , , "",  					 40)



** StateIcons

oIL1 = MNewObject(This.Parent, Sys(2015), '_imagelist5', 'Libs\_BaseOleCtrl.vcx')

oIL1.ListImages.Add(, 'BTNEXPAND',   oApp.ImageListST.ListImages('BTNEXPAND').ExtractIcon())		&& 1

oIL1.ListImages.Add(, 'BTNCOLLAPSE', oApp.ImageListST.ListImages('BTNCOLLAPSE').ExtractIcon())	&& 2

LV_SetStateImageList(This.hWnd, oIL1.hImageList)



** Icons / SmallIcons

oIL2 = MNewObject(This.Parent, Sys(2015), '_imagelist5', 'Libs\_BaseOleCtrl.vcx')

oIL2.ListImages.Add(, 'DOCUMENT', oApp.ImageList16.ListImages('DOCUMENT').ExtractIcon())

This.Icons 		 = oIL2

This.SmallIcons = This.Icons



This.FullRowSelect = .T.



** Supporto per customDraw e font-changing

This.AddProperty('hOldFont',   0)		&& devo salvare il font selezionato nel DC quando lo vario per ripristinarlo nel CustomDraw_PostXxx

This.AddProperty('hNewFontI',  0)		&& hfont clonato dal DC con attributo Italic     On

This.AddProperty('hNewFontU',  0)		&& hfont clonato dal DC con attributo Underlined On

This.AddProperty('hNewFontUM', 0)		&& hfont creato ex novo: simile a quello dell'hDC con dimensione -2



This.AddProperty('hCursorNorm', xGetCursor()				)	&& Vedere MouseMove

This.AddProperty('hCursorHand', LoadCursor(0, 32649)	)	&& #define IDC_HAND MAKEINTRESOURCE(32649)  in WinUser.h



This.CustomDraw_Enable(2)

ENDPROC

PROCEDURE load

Local oItem

Local cPicSep, cPicSepPrzUn, cVLAlias

Local lVisible 



** Picture della valuta

With Thisform.PF.pgGenerale

	cVLAlias = .txtCd_VL.Field.FKAlias

	If Empty(cVLAlias)

		.txtCd_VL.Field.Refresh()

		cVLAlias = .txtCd_VL.Field.FKAlias

	Endif

	cPicSep		 = Eval(cVLAlias + '.PicSep'     )

	cPicSepPrzUn = Eval(cVLAlias + '.PicSepPrzUn')

EndWith 



This.ListItems.Clear()



Select Righe

Scan

	** Nella property .KEY metto il valore di ID_DORig e nel .TAG una "R" se si tratta di riga di riferimento!

	oItem = This.ListItems.Add(, 'Id_DoRig' + Tran(Righe.Id_DoRig), Nvl(Rtrim(Righe.Cd_AR), ''))

	oItem.Tag = Righe.TipoRigaRif



	If Righe.Expandable

		LV_SetStateImage(This.HWnd, oItem.Index, 1)



		lVisible = .T.		&& se c'è almemo una riga Expandable, cioè che si riferisce ad un documento EVADENTE/EVASO allora rendo visibile la LV

	EndIf 



	oItem.SubItems(1) = Rtrim(Nvl(Righe.Descrizione, ''))

	oItem.SubItems(2) = Transform(Righe.Riga)

	If IsEmpty(Righe.TipoRigaRif)

		oItem.SubItems(3) = Ltrim(Tran(Righe.Qta, oApp.Preferenza.PicSepQta))

		oItem.SubItems(4) = Rtrim(Nvl(Righe.Cd_ARMisura, ''))



		If This.Mode = 'EVASI'

		

			If Righe.QtaEvasa != 0

				oItem.SubItems(5) = Iif(Righe.Cd_ARMisura != Righe.Cd_ARMisura1, '(' + Rtrim(Nvl(Righe.Cd_ARMisura1, '')) + ') ', '') + Ltrim(Tran(Righe.QtaEvasa, oApp.Preferenza.PicSepQta))



				If This.ColumnHeaders(6).Width = 0 And (Righe.Cd_ARMisura != Righe.Cd_ARMisura1 Or (Righe.QtaEvasa != 0 And Righe.Qta != Righe.QtaEvasa))

					This.ColumnHeaders(6).Width = 65

				EndIf 

			EndIf 

			

		Else

			oItem.SubItems(5) = ''	&& QtaEvasa

		EndIf 



		oItem.SubItems(6) = Ltrim(Tran(Righe.QtaEvadibile, oApp.Preferenza.PicSepQta))

		oItem.SubItems(7) = Rtrim(Righe.Cd_VL)

		oItem.SubItems(8) = Ltrim(Tran(Righe.PrezzoUnitarioV, cPicSepPrzUn))

		oItem.SubItems(9) = Rtrim(Righe.ScontoRiga)

		oItem.SubItems(10) = Ltrim(Tran(Righe.PrezzoTotaleV, cPicSep))

		oItem.SubItems(11) = Nvl(Righe.Cd_Aliquota, '')

	EndIf 

	

EndScan 



This.Visible = lVisible

ENDPROC

PROCEDURE customdraw_drawsubitem

Lparameters nItem, nSubItem, hDC, nForeColor, nBackColor, lParam



** Inizializzazioni dei nuovi font una tantum; lo posso fare solo ora xché se lo faccio nell'init clono e modifico un font errato

If This.hNewFontU = 0

	This.hNewFontU = CloneDCFont(hDC, , ,1)	&& Clono il font del DC e ne cambio in ON solo l'attributo Underlined

EndIf		

If This.hNewFontI = 0

	This.hNewFontI = CloneDCFont(hDC, ,1, )	&& Clono il font del DC e ne cambio in ON solo l'attributo Italic

EndIf	

If This.hNewFontUM = 0

	This.hNewFontUM = CloneDCFontEx(hDC, "-2")	&& Font con height minore di 2

EndIf	



If This.ListItems(nItem+1).Tag = 'R'		&& righe di riferimento

	nForeColor = Rgb(0,0,0)

	nBackColor = oApp.ColorInfoBK

	This.hOldFont = SelectObject(hDC, This.hNewFontI)

	Return CDRF_DODEFAULT + CDRF_NEWFONT

EndIf



Local nRet

nRet = CDRF_DODEFAULT



** Unità di misura, font piccolo per ogni altro tipo di riga

If nSubItem = 4

	This.hOldFont = SelectObject(hDC, This.hNewFontUM)

	nRet = CDRF_DODEFAULT + CDRF_NEWFONT

EndIf 



Do Case

	Case This.GetItemIndent(nItem+1) > 0											&&	righe figlie che evidenziano i documenti evasi/evadenti

		nForeColor = Rgb(000,000,202)

		nBackColor = Rgb(245,245,245)

		If nSubItem = 12	&& Link "Modifica": font underline

			This.hOldFont = SelectObject(hDC, This.hNewFontU)

			nRet = CDRF_DODEFAULT + CDRF_NEWFONT

		EndIf 



	Case LV_GetStateImage(This.HWnd, This.ListItems(nItem+1).Index) != 0	&& righe padre

		nForeColor = oApp.ColorDecodedField

		nBackColor = Rgb(255,255,255)

		

	Otherwise 															

		nForeColor = Rgb(000,000,000)

		nBackColor = Rgb(255,255,255)



EndCase



** Evidenzio la quantità evasa quando c'è un um tra parentesi o quando diversa dalla qta

If nSubItem = 5

	oItem = This.ListItems(nItem+1)

	If !Empty(oItem.SubItems(5))

		If Left(oItem.SubItems(5), 1) = '(' Or Val(oItem.SubItems(3)) != Val(oItem.SubItems(5))

			nForeColor = Rgb(255,0,0)

		EndIf 

	EndIf

EndIf 





Return nRet 	



ENDPROC

PROCEDURE MouseMove

Lparameters button, shift, x, y



oSubItem = This.SubItemHitTest(x, y)



** Non funziona :-(

**	If oSubItem.Flags = 4 And oSubItem.SubItem = 8 And Left(This.ListItems(oSubItem.Item+1).Key, 3) = 'Rev'

**		If This.MousePointer != 99

**			This.MousePointer = 99  && 99 ccCustom

**		EndIf

**	Else

**		If This.MousePointer != 0

**			This.MousePointer = 0   && default

**		EndIf 

**	EndIf



If (oSubItem.Flags = 4 And oSubItem.SubItem = 12 And This.ListItems(oSubItem.Item+1).SubItems(12) != '') Or ;	&& Sono sopra il link "Modifica"

	(Inlist(oSubItem.Flags, 2, 4) And oSubItem.SubItem = 0 And This.ListItems(oSubItem.Item+1).SmallIcon = 'DOCUMENT' And This.ListItems(oSubItem.Item+1).SubItems(12) != '')		&& Sono sopra un documento con il link "Modifica" attivo...

	SetCursor(This.hCursorHand)

Else

	SetCursor(This.hCursorNorm) 

EndIf

ENDPROC

PROCEDURE onclick

Lparameters oItem As MSComctlLib.ListItem, nShift, lOnIcon



If oItem.SmallIcon = 'DOCUMENT'

	Local oSubItem

	

	oSubItem = CreateObject('Empty')

	AddProperty(oSubItem, 'Item', 	oItem.Index-1)

	AddProperty(oSubItem, 'SubItem', 12)

	This.OnSubitemClick(oSubItem)

EndIf  

ENDPROC

PROCEDURE onrightclick

Lparameters oItem As MSComctlLib.ListItem, nShift, nMRow, nMCol, lOnIcon



Local nChoice, nOldWA

Local cStmt



nChoice = 0

nOldWA = Select()



If oItem.SmallIcon = 'DOCUMENT' And oItem.SubItems(12) = 'Modifica'



	Text To cStmt NOSHOW TEXTMERGE

		Select 

			ReportDocAll.Descrizione,

			DoReport.Device,

			DoReport.Ud_ReportDoc

		From DoReport Join ReportDocAll On DoReport.Ud_ReportDoc = ReportDocAll.Ud_ReportDoc

		Where DoReport.Cd_DO = <<FormatC4Spt(Left(oItem.Text, 3))>> AND

			  (DoReport.ComputerName Is Null OR DoReport.ComputerName = <<Format4SPT(oApp.ComputerName)>>)

	EndText 

	xSqlExec(cStmt, 'Previews')



	With Thisform.SCMenu

		.ClearMenu()

		.AddMenuBar(Thisform.TM_(,"62BAAD7B-C28C-4FFB-80BE-A233A7729F5A", 	"Visualizza Documento"),						'This.nChoice = 1',,,,.F.)



		Select Previews

		Scan

			.AddMenuBar(Thisform.TM_(,"5E98AFED-C959-49A0-9696-000DFE46E60D", "Anteprima (%1!)", Rtrim(Descrizione)), 	'This.nChoice = ' + Transform(Recno()+1),,,,.F.)

		EndScan

		.AddMenuBar('\-')

		.AddMenuBar(Thisform.TM_(,"C05F7F99-FA97-43C0-83DD-7AD12B0CC120", 	"Annulla"), 										'This.nChoice = 0')

		nChoice = .ShowMenu()



		Do Case

			Case nChoice = 1			

			

				Local oSubItem

				

				oSubItem = CreateObject('Empty')

				AddProperty(oSubItem, 'Item', 	oItem.Index-1)

				AddProperty(oSubItem, 'SubItem', 12)

				This.OnSubitemClick(oSubItem)



			Case nChoice > 1

			

				Local aPrintInfo[1]

				Local oRepDocEng 

				Local nId_DOTes, nId_DORig

			

				nId_DORig = Val(Substr(oItem.Key, 9))

				nId_DOTes = xSqlExec2Var('Select Id_DOTes From DoRig Where Id_DORig = ' + Transform(nId_DORig))



				Goto (nChoice-1) In Previews

				aPrintInfo[1] = NewObjPrintInfo(Previews.Ud_ReportDoc, 1, Rtrim(Device))

				oRepDocEng = NewObject1('ReportDoc', 'Libs\ReportDoc.vcx', '', Thisform.Ditta)

				oRepDocEng.DocPrint(nId_DOTes, @aPrintInfo, RE_ACT_PRINT_TO_SCREEN)

		Endcase



	EndWith

	

	Use In Previews

	Select (nOldWA)

Endif



ENDPROC

PROCEDURE Destroy



If This.hNewFontI != 0

	DeleteObject(This.hNewFontI)

EndIf

If This.hNewFontU != 0

	DeleteObject(This.hNewFontU)

EndIf

If This.hNewFontUM != 0

	DeleteObject(This.hNewFontUM)

EndIf



DoDefault()

ENDPROC


*======================================================================

*** CLASS / OBJECT: pgtotali (BaseClass: container, Parent: ) ***
*** PROPERTIES ***
Comment = "3A1E4EF6-3DC2-4DFA-BEDF-D21395935BC6"

Width = 600

Height = 405

Name = "pgtotali"


*** METHODS ***
PROCEDURE Init

Lparameters oPage



Local cStr

Local i



This.AddProperty('CurrentVL', 'EUR')



DoDefault(oPage)



** ----- LICADAPTER

If !oApp.LicInfo.CG_Main

	This.lblMerce 	.Visible = .F.

	This.LV_Merce 	.Visible = .F.

	This.LV_Merce2	.Visible = .F.

	This.lblIva   	.Visible = .F.

	This.LV_Iva 	.Visible = .F.

	This.LV_IVa2	.Visible = .F.

	

	ObjMov(This.LV_Tot   ,,,, This.LV_Tot.Height 	+ This.LV_Merce.Height + This.LV_Iva.Height - 2)

	ObjMov(This.lblTotali,,,, This.lblTotali.Height + This.LblMerce.Height + This.LblIva.Height - 2)

	

	ObjMov(This.LV_Provv,,,,, 15)

	ObjMov(This.lblProvv,,,,,  5)

EndIf



** ---------------------------------------------------------------------------



BindEvent(This.lblMerce, 'Height', This, 'Resize', 1) 

BindEvent(This.lblIVA  , 'Height', This, 'Resize', 1) 

BindEvent(This.LblProvv, 'Height', This, 'Resize', 1) 



This.Resize()



** ---------------------------------------------------------------------------

** Ripristino larghezza colonne 



cStr = Thisform.UserPrefGetProperty(This, UP_SCOPE_NONE, 'LV_Merce', '')

For i = 1 To ALines(aVal, cStr, 1+2+4, ';')

	This.LV_Merce.ColumnHeaders(i).Width = Val(aVal[i])

Next



cStr = Thisform.UserPrefGetProperty(This, UP_SCOPE_NONE, 'LV_Merce2', '')

For i = 1 To ALines(aVal, cStr, 1+2+4, ';')

	This.LV_Merce2.ColumnHeaders(i).Width = Val(aVal[i])

Next



cStr = Thisform.UserPrefGetProperty(This, UP_SCOPE_NONE, 'LV_Iva', '')

For i = 1 To ALines(aVal, cStr, 1+2+4, ';')

	This.LV_Iva.ColumnHeaders(i).Width = Val(aVal[i])

Next



cStr = Thisform.UserPrefGetProperty(This, UP_SCOPE_NONE, 'LV_Iva2', '')

For i = 1 To ALines(aVal, cStr, 1+2+4, ';')

	This.LV_Iva2.ColumnHeaders(i).Width = Val(aVal[i])

Next

ENDPROC

PROCEDURE UIEnable

LPARAMETERS lEnable



IF lEnable AND Thisform.Mode != FEDIMODE_SHOW

	This.Refresh()

Endif

ENDPROC

PROCEDURE Refresh

Local cImporti, cStmt, cPicSep

Local nLeft



If This.CurrentVL = 'EUR'

	cPicSep = xSqlExec2Var("Select PicSep From VL Where Cd_VL = 'EUR'")

Else

	cPicSep = xSqlExec2Var("Select PicSep From VL Where Cd_VL = " + FormatC4Spt(DoTes.Cd_VL))

EndIf 

This.AddProperty('PicSep', NEvl(cPicSep, '###,###,###.##'))



This.Resize()



If Thisform.Mode = FEDIMODE_SHOW



	** ---------------------------------------------------------------------------------------------------------------

	** MERCE



	If InList(DOTes.TipoDocumento, 'F', 'A', 'N')

		* Documenti Contabili



		If This.CurrentVL = 'EUR'

			Text To cImporti 

					[VL]						= 'EUR',

			/*T */[Importo]				= CGMovR.ImportoE,

			EndText 

		Else

			Text To cImporti 

					[VL]						= CGMovT.Cd_VL,

			/*T */[Importo]				= CGMovR.ImportoV,

			EndText 	

		EndIf 		

				

		Text To cStmt TextMerge NoShow

			Select 

					[R]						= CGMovR.Riga,

					[CliFor]					= CGMovT.Cd_Cf,

					[Conto]					= CGMovR.Cd_CGConto,

					[Descrizione]			= Case When CGMovR.Cd_CF Is Null Then CGConto.Descrizione Else CF.Descrizione End,		

					[Segno]					= CGMovR.DareAvere,

					<<cImporti>>

					[Partita]				= CGMovR.PartNum + '-' + Convert(Char(4), CGMovR.PartAnno),

					[Cespite]				= CS.Cd_CS + ' ' + CS.Descrizione,

					[Commessa]				= CGMovR.Cd_Sottocommessa,

					[VoceAnalisi]			= dbo.afn_CatCodeDesc(CGMovR.Cd_CAVda, CAVda.Descrizione, 0x0400),

					[Formula]				= dbo.afn_CatCodeDesc(CGMovR.Cd_CAFormula, CAFormula.Descrizione, 0x0400),

					[CentroAnalisi]		= dbo.afn_CatCodeDesc(CGMovR.Cd_CACda, CACda.Descrizione, 0x0400),

					[InizioComp]			= CGMovR.RR_DataInizio,

					[FineComp]				= CGMovR.RR_DataFine,

					[ContoRR]				= dbo.afn_CatCodeDesc(CGMovR.RR_Cd_CGConto, RRConto.Descrizione, 0x0400)

			

			From CGMovR

							  Join CGMovT		ON CGMovR.Id_CGMovT   = CGMovT.Id_CGMovT

				Left Outer Join CGConto		ON CGMovR.Cd_CGConto = CGConto.Cd_CGConto

				Left Outer Join CF			ON CGMovR.Cd_CF = CF.Cd_CF

				Left Outer Join CS			ON CGMovR.Cd_CS = CS.Cd_CS

				Left Outer Join CAVda		ON CGMovR.Cd_CAVda = CAVda.Cd_CAVda

				Left Outer Join CACda		ON CGMovR.Cd_CACda = CACda.Cd_CACda

				Left Outer Join CAFormula	ON CGMovR.Cd_CAFormula = CAFormula.Cd_CAFormula

				Left Outer Join CGConto	RRConto ON CGMovR.RR_Cd_CGConto = RRConto.Cd_CGConto



			Where

				CGMovT.Id_DoTes = <<DoTes.Id_DoTes>> And CGMovR.TipoRiga = 1



			Order By

				CGMovR.Riga

		EndText 

		

	Else

		* Documenti non Contabili



		If This.CurrentVL = 'EUR'

			Text To cImporti 

					[VL]				= 'EUR',

			/*T */[Importo]		= DOMerce.ImportoE,

			EndText 

		Else

			Text To cImporti 

					[VL]				= DOMerce.Cd_VL,

			/*T */[Importo]		= DOMerce.ImportoV,

			EndText 	

		EndIf 

		

		Text To cStmt TextMerge NoShow



			Select

					[Conto]			= DOMerce.Cd_CGConto,

					[Descrizione]	= CGConto.Descrizione,

					<<cImporti>>

					[SottoCommessa]= DOMerce.CD_SottoCommessa

			From

				DOMerce

				Left Join CGConto On DOMerce.Cd_CGConto = CGConto.Cd_CGConto

			Where

				Id_DOTes = <<FormatI4Spt(DoTes.Id_DoTes)>>

		EndText 



	EndIf 



	xSqlExec(cStmt, 'crMerce')





	** ---------------------------------------------------------------------------------------------------------------

	** IVA



	If InList(DOTes.TipoDocumento, 'F', 'A', 'N')

		* Documenti Contabili

		

		If This.CurrentVL = 'EUR'

			Text To cImporti 

					[VL]					= 'EUR',

			/*T */[Imponibile]		= CGMovR.ImponibileE,

			/*T */[Imposta]			= CGMovR.ImpostaE,

					[PercIND]			= CGMovR.PercInd,

			/*T */[ImpostaIND]		= CGMovR.ImportoIndE,

			EndText 

		Else

			Text To cImporti 

				 	[VL]					= CGMovT.Cd_VL,

			/*T */[Imponibile]		= CGMovR.ImponibileV,

			/*T */[Imposta]			= CGMovR.ImpostaV,

					[PercIND]			= CGMovR.PercInd,

			/*T */[ImpostaIND]		= CGMovR.ImportoIndV,

			EndText 	

		EndIf 

		

		Text To cStmt TextMerge NoShow

			Select

					[R]					= CGMovR.Riga,

					[Aliquota]			= CGMovR.CD_Aliquota,

										

					<<cImporti>>



					[RC]					= CGMovR.Cd_ReverseCharge,

					[Segno]				= CGMovR.DareAvere,

					[Mese]				= CGMovR.MesePlafond,

					[Anno]				= CGMovR.AnnoPlafond,

					[ContoIVA]			= CGMovR.Cd_CGConto,

					[CodiceLiq]			= CGMovR.Cd_CGLiq,

					[DataComp]			= CGMovR.DataCompIva,

					[Ventilare]			= dbo.afn_Decode_Logico_Ex(CGMovR.DaVentilare, 0),

					[Cespite]			= dbo.afn_Decode_Logico_Ex(CGMovR.Cespite, 0),

					[Leasing]			= dbo.afn_Decode_Logico_Ex(CGMovR.Leasing, 0),

					[BeneServ]			= Case CGMovR.TipoBeneServizio When 'B' Then 'Bene' When 'S' Then 'Servizio' Else '' End,

					[Commessa]			= CGMovR.Cd_SottoCommessa,

					

			/*X */[Perc IVA]			= CGMovR.PercIva

			

			From 			 CGMovR

					  Join CGMovT	 On CGMovR.Id_CGMovT   = CGMovT.Id_CGMovT

				Left Join CGConto	 On CGMovR.Cd_CGConto  = CGConto.Cd_CGConto

				Left Join Aliquota On CGMovR.Cd_Aliquota = Aliquota.Cd_Aliquota

			Where

				CGMovT.Id_DoTes = <<FormatI4Spt(DoTes.Id_DoTes)>> And CGMovR.TipoRiga = 2

			Order By 

				CGMovR.Riga		

				

		EndText 

		

	Else

		* Documenti non Contabili



		If This.CurrentVL = 'EUR'

			Text To cImporti 

					[VL]				 = 'EUR',

			/*T */[Imponibile]	 = ImponibileE,

			/*T */[Imposta]	 	 = ImpostaE,

			EndText 

		Else

			Text To cImporti 

					[VL]				 = T.Cd_VL,

			/*T */[Imponibile] 	 = ImponibileV,

			/*T */[Imposta]   	 = ImpostaV,

			EndText 	

		EndIf 



		Text To cStmt TextMerge NoShow

			Select 

					[Aliquota]		 = I.Cd_Aliquota,

					

					<<cImporti>>



					[RC]				 = I.Cd_ReverseCharge,

					[Conto]			 = I.Cd_CGConto,

					[SottoCommessa] = I.Cd_DOSottoCommessa,

			/*H */[Omaggio]		 = I.Omaggio

			

			From 

					  DOIva I 

				Join DOTes T On I.Id_DOTes = T.Id_DoTes 

				Join VL		 On T.Cd_VL		= VL.Cd_VL 



			 Where 

			 	I.Id_DOTes = <<FormatI4Spt(DoTes.Id_DoTes)>>

		EndText 



	EndIf



	xSqlExec(cStmt, 'crIVA')





	** ------------------------------------------------------------------------------------------------------------------

	** Provvigioni



	If RecSignTest(This, Thisform.DE.DOTes)

		Thisform.DE.DoRig.Requery('DORig.Id_DOTes = ' + OldVal4Spt('DOTes', 'Id_DOTes'))

	EndIf 



	Select 													;

		'1'						As Tipo,					;

		R.Riga,												;

		R.Cd_AR,												;

		R.Descrizione,										;

		Iif(This.CurrentVL = 'EUR', 'EUR', 				DOTes.Cd_VL)		As VL,					;

		Iif(This.CurrentVL = 'EUR', R.PrezzoTotaleE, R.PrezzoTotaleV)	As PrezzoTotale,		;

		R.ProvvigioneRiga_1	As Provv,				;

		Iif(This.CurrentVL = 'EUR', Round(R.ValProvvigione_1 / DoTes.Cambio, 2), R.ValProvvigione_1)	As ValoreProvv			;

	From 														;

		DoRig R 												;

	Where 													;

		R.ValProvvigione_1 != 0	And R.TipoPc <> 'C'	;

																;

	Union All												;

																;

	select 													;

		'2',													;

		R.Riga,												;

		R.Cd_AR,												;

		R.Descrizione,										;

		Iif(This.CurrentVL = 'EUR', 'EUR', 				DOTes.Cd_VL),										;

		Iif(This.CurrentVL = 'EUR', R.PrezzoTotaleE, R.PrezzoTotaleV),									;

		R.ProvvigioneRiga_2,								;

		Iif(This.CurrentVL = 'EUR', Round(R.ValProvvigione_2 / DoTes.Cambio, 2), R.ValProvvigione_2)								;

	From 														;

		DoRig R  											;

	Where 													;

		R.ValProvvigione_2 != 0 And R.TipoPc <> 'C'	;

																;

	Order by 1, 2											;

	Into Cursor crProvv



EndIf 



** ------------------------------------------------------------------------------------------------------------------



This.LV_Tot 	.Refresh(.T.)



If Thisform.Mode = FEDIMODE_SHOW

	This.LV_Merce	.Refresh(.T.)

	This.LV_IVA		.Refresh(.T.)

	This.LV_Merce2	.Refresh(.T.)

	This.LV_IVA2	.Refresh(.T.)

	This.LV_Provv	.Refresh(.T.)

EndIf  



nLeft = Iif(Thisform.Mode = FEDIMODE_SHOW, This.LV_Tot.Left, 3000)

This.lblMerce.Visible = (Thisform.Mode = FEDIMODE_SHOW)

This.lblIva  .Visible = (Thisform.Mode = FEDIMODE_SHOW)

This.LblProvv.Visible = (Thisform.Mode = FEDIMODE_SHOW)



If InList(DOTes.TipoDocumento, 'F', 'A', 'N')

	* Documenti Contabili

	ObjMov(This.LV_Merce,  nLeft)

	ObjMov(This.LV_IVA,	  nLeft)

	ObjMov(This.LV_Merce2, 3000)

	ObjMov(This.LV_IVA2,	  3000)

Else

	* Documenti non Contabili

	ObjMov(This.LV_Merce,  3000)

	ObjMov(This.LV_IVA,	  3000)

	ObjMov(This.LV_Merce2, nLeft)

	ObjMov(This.LV_IVA2,	  nLeft)

EndIf  



ObjMov(This.LV_Provv,	  nLeft)



** ------------------------------------------------------------------------------------------------------------------



Use In Select('crMerce')

Use In Select('crIVA')

&&Use In crProvv   -> mi serve nel LV_Provv.Click()

ENDPROC

PROCEDURE Destroy

Local cStr, oCol



** ---------------------------------------------------------------------------

** Salvo larghezza colonne 



cStr = ''

For Each oCol In This.LV_Merce.ColumnHeaders

	cStr = cStr + ';' + Transform(oCol.Width)

Next

Thisform.UserPrefSetProperty(This, UP_SCOPE_NONE, 'LV_Merce', cStr)



cStr = ''

For Each oCol In This.LV_Merce2.ColumnHeaders

	cStr = cStr + ';' + Transform(oCol.Width)

Next

Thisform.UserPrefSetProperty(This, UP_SCOPE_NONE, 'LV_Merce2', cStr)



cStr = ''

For Each oCol In This.LV_Iva.ColumnHeaders

	cStr = cStr + ';' + Transform(oCol.Width)

Next

Thisform.UserPrefSetProperty(This, UP_SCOPE_NONE, 'LV_Iva', cStr)



cStr = ''

For Each oCol In This.LV_Iva2.ColumnHeaders

	cStr = cStr + ';' + Transform(oCol.Width)

Next

Thisform.UserPrefSetProperty(This, UP_SCOPE_NONE, 'LV_Iva2', cStr)

ENDPROC

PROCEDURE Resize



This.lblProvv.Caption = Iif(This.lblProvv.Height < 100, TX_(, "068B2315-8B1B-4627-8F10-C52CFCEC9779", 'Provv.'), TX_(, "26C313AD-61C5-443C-85C3-9DF5ABC9210D", 'Provvigioni'))



If InList(DOTes.TipoDocumento, 'F', 'A', 'N')

	** 

	This.lblMerce.ToolTipText = TX_(, "BC56370F-5732-4DDF-8CBB-BE2E76BCC0B6", 'I dati visualizzati sono ricavati dal Movimento Contabile collegato')

	This.lblIVA.ToolTipText   = This.lblMerce.ToolTipText

	**

	This.lblMerce.Caption 	  = Iif(This.lblMerce.Height < 138, TX_(, "A0F879AD-C254-4211-8CCB-490D42C45B25", 'Merce *'), TX_(, "01513627-C7AD-4176-BBD1-50DFE5699735", 'Merce (mov.cont.)'))

	This.lblIVA.Caption   	  = Iif(This.lblIVA  .Height < 120, TX_(, "D1060E08-B2D4-4C29-A1B1-1553E03D821D", 'IVA *')  , TX_(, "A024E906-5493-4496-AE03-E108D0D07B3C", 'IVA (mov.cont.)')  )

Else

	This.lblMerce.Caption 	  = TX_(, "FAE19741-AF48-483D-952F-4DBD37528156", 'Merce')

	This.lblMerce.ToolTipText = ''

	This.lblIVA.Caption   	  = TX_(, "157FE62F-19C4-4D7A-B35B-6716EAF0FEAF", 'IVA')

	This.lblIVA.ToolTipText   = ''

EndIf 

ENDPROC


*======================================================================

*** CLASS / OBJECT: LV_Merce (BaseClass: olecontrol, Parent: pgtotali) ***
*** PROPERTIES ***
Comment = "AB2D9630-92BB-4F98-AE90-A0DF5E83ED90"

Top = 184

Left = 25

Height = 73

Width = 573

Anchor = 75

Name = "LV_Merce"


*** METHODS ***
PROCEDURE Refresh

Lparameters lForce



If lForce

	This.Load()

EndIf 

ENDPROC

PROCEDURE Init

Local cStr, aVal[1]

Local i

DoDefault()



** Add the ListView ColumnHeaders

This.ColumnHeaders.Add( , , TX_(, "54762A74-01B3-4222-9525-A72E2156F783", "R"), 						10)

This.ColumnHeaders.Add( , , TX_(, "906DB1F8-7262-433F-894C-5934F58F82AD", "Cli/For"), 				50)

This.ColumnHeaders.Add( , , TX_(, "4A22A2C6-168B-401E-8FCC-59C7BE481A22", "Conto"), 				70)

This.ColumnHeaders.Add( , , TX_(, "907FB9EA-B5CA-4159-A087-BA39B6893FB5", "Descrizione"), 		80)

This.ColumnHeaders.Add( , , TX_(, "D33A3A82-9687-48C3-A502-16F5C4B86875", "Segno"), 				10)

This.ColumnHeaders.Add( , , TX_(, "B091302C-8A49-4FD6-B17A-8159BABDFA65", "VL"), 					20)

This.ColumnHeaders.Add( , , TX_(, "087DB30A-CA3E-4DE5-A9B5-497A1F7B94CC", "Importo"), 				70, 1)

This.ColumnHeaders.Add( , , TX_(, "52215B01-6D16-40BB-9337-AFAC275438F9", "Partita"), 				50)

This.ColumnHeaders.Add( , , TX_(, "567ADF4D-2BD4-4B85-A403-346149123F08", "Cespite"), 				80)

This.ColumnHeaders.Add( , , TX_(, "3173EFA2-540F-4EC7-B1E4-679BE681B1A6", "Commessa"), 			60)

This.ColumnHeaders.Add( , , TX_(, "CB7C0CEA-C844-4334-B98A-582BE8029C27", "Voce di analisi"), 	60)

This.ColumnHeaders.Add( , , TX_(, "A4B611D2-10A2-4E4D-B47F-09617551D36D", "Formula"), 				60)

This.ColumnHeaders.Add( , , TX_(, "E658B732-6C56-4302-9C80-23C5F80C4424", "Centro di analisi"), 60)

This.ColumnHeaders.Add( , , TX_(, "CDABB5EB-662F-401A-8196-D8E7447A364C", "Inizio Comp"), 		54)

This.ColumnHeaders.Add( , , TX_(, "6AC198AD-D253-4246-8D09-FD8D11490159", "Fine Comp"), 			54)

This.ColumnHeaders.Add( , , TX_(, "4E34FC58-1477-41E0-808F-F256660F511A", "Conto RR"), 			60)



This.FullRowSelect = .T.



ENDPROC

PROCEDURE load

This.ListItems.Clear()



If InList(DOTes.TipoDocumento, 'F', 'A', 'N')



	Select crMerce

	Scan

		oItem = This.ListItems.Add(, , Transform(R))

		oItem.SubItems( 1) = Nvl(CliFor, '')

		oItem.SubItems( 2) = Nvl(Conto, '')

		oItem.SubItems( 3) = Nvl(Rtrim(Descrizione), '')

		oItem.SubItems( 4) = Nvl(Segno, '')

		oItem.SubItems( 5) = Nvl(VL, '')

		oItem.SubItems( 6) = Ltrim(Transform(Importo, This.Parent.PicSep))

		oItem.SubItems( 7) = Nvl(Partita, '')

		oItem.SubItems( 8) = Nvl(Cespite, '')

		oItem.SubItems( 9) = Nvl(Commessa, '')

		oItem.SubItems(10) = Nvl(Rtrim(VoceAnalisi), '')

		oItem.SubItems(11) = Nvl(Rtrim(Formula), '')

		oItem.SubItems(12) = Nvl(Rtrim(CentroAnalisi), '')

		oItem.SubItems(13) = Nvl(DtoC(InizioComp), '')

		oItem.SubItems(14) = Nvl(Dtoc(FineComp), '')

		oItem.SubItems(15) = Nvl(Rtrim(ContoRR), '')

	EndScan 



EndIf 

ENDPROC


*======================================================================

*** CLASS / OBJECT: LV_Merce2 (BaseClass: olecontrol, Parent: pgtotali) ***
*** PROPERTIES ***
Comment = "C28480DC-1C0E-42A7-8480-52078A531E33"

Top = 184

Left = 25

Height = 73

Width = 573

Anchor = 75

Name = "LV_Merce2"


*** METHODS ***
PROCEDURE Refresh

Lparameters lForce



If lForce

	This.Load()

EndIf 

ENDPROC

PROCEDURE load

This.ListItems.Clear()



If !InList(DOTes.TipoDocumento, 'F', 'A', 'N')



	Select crMerce

	Scan

		oItem = This.ListItems.Add(, , Conto)

		oItem.SubItems(1) = Nvl(Rtrim(Descrizione), '')

		oItem.SubItems(2) = Nvl(VL, '')

		oItem.SubItems(3) = Ltrim(Transform(Importo, This.Parent.PicSep))

		oItem.SubItems(4) = Nvl(SottoCommessa, '')

	EndScan 



EndIf 

ENDPROC

PROCEDURE Init

DoDefault()



** Add the ListView ColumnHeaders

This.ColumnHeaders.Add( , , TX_(, "641CCF06-44E4-4FCB-9948-8F8EE31F9555", "Conto"), 				70)

This.ColumnHeaders.Add( , , TX_(, "0E174E59-8517-423D-BED7-F83A611B1109", "Descrizione"), 		80)

This.ColumnHeaders.Add( , , TX_(, "EABD4EC4-D886-445D-B144-51DC4D8E35A7", "VL"), 					20)

This.ColumnHeaders.Add( , , TX_(, "E2057E02-6915-41A8-87BE-FE7AD57995BB", "Importo"), 				70, 1)

This.ColumnHeaders.Add( , , TX_(, "A5C85047-6A3F-40C1-8FDB-4917448E6696", "Commessa"), 			60)



This.FullRowSelect = .T.



ENDPROC


*======================================================================

*** CLASS / OBJECT: LV_Iva (BaseClass: olecontrol, Parent: pgtotali) ***
*** PROPERTIES ***
Comment = "8449CAAD-7521-4CA4-AE3F-E563E6793181"

Top = 256

Left = 25

Height = 74

Width = 573

Anchor = 90

Name = "LV_Iva"


*** METHODS ***
PROCEDURE Refresh

Lparameters lForce



Iif(lForce, This.Load(), .T.)

ENDPROC

PROCEDURE load

This.ListItems.Clear()



If InList(DOTes.TipoDocumento, 'F', 'A', 'N')



	Select crIva

	Scan

		oItem = This.ListItems.Add(, , Transform(R))

		oItem.SubItems( 1) = Nvl(Aliquota, '')

		oItem.SubItems( 2) = Nvl(VL, '')

		oItem.SubItems( 3) = Ltrim(Transform(Imponibile, This.Parent.PicSep))

		oItem.SubItems( 4) = Ltrim(Transform(Imposta, This.Parent.PicSep))

		oItem.SubItems( 5) = Ltrim(Transform(PercIND, '####,##')) + '%'			

		oItem.SubItems( 6) = Ltrim(Transform(ImpostaIND, This.Parent.PicSep))

		oItem.SubItems( 7) = Nvl(RC, '')

		oItem.SubItems( 8) = Nvl(Segno, '')

		oItem.SubItems( 9) = Nvl(Mese, '')

		oItem.SubItems(10) = Nvl(Anno, '')

		oItem.SubItems(11) = Nvl(ContoIVA, '')

		oItem.SubItems(12) = Nvl(CodiceLiq, '')

		oItem.SubItems(13) = Nvl(DataComp, '')

		oItem.SubItems(14) = Nvl(Ventilare, '')

		oItem.SubItems(15) = Nvl(Cespite, '')

		oItem.SubItems(16) = Nvl(Leasing, '')

		oItem.SubItems(17) = Nvl(BeneServ, '')

		oItem.SubItems(18) = Nvl(Commessa, '')

	EndScan 



EndIf 

ENDPROC

PROCEDURE Init

DoDefault()



** Add the ListView ColumnHeaders

This.ColumnHeaders.Add( , , "R", 						10)

This.ColumnHeaders.Add( , , "Aliquota", 				50)

This.ColumnHeaders.Add( , , "VL", 						20)

This.ColumnHeaders.Add( , , "Imponibile", 			70, 1)

This.ColumnHeaders.Add( , , "Imposta", 				70, 1)

This.ColumnHeaders.Add( , , "% IND", 					30, 1)

This.ColumnHeaders.Add( , , "Imposta IND", 			70, 1)

This.ColumnHeaders.Add( , , "RC", 						30)

This.ColumnHeaders.Add( , , "Segno", 					10)

This.ColumnHeaders.Add( , , "Mese", 					30)

This.ColumnHeaders.Add( , , "Anno", 					30)

This.ColumnHeaders.Add( , , "Conto Iva", 				70)

This.ColumnHeaders.Add( , , "Codice Liq", 			50)

This.ColumnHeaders.Add( , , "Data Comp", 				54)

This.ColumnHeaders.Add( , , "Ventilare", 				40)

This.ColumnHeaders.Add( , , "Cespite", 				40)

This.ColumnHeaders.Add( , , "Leasing", 				40)

This.ColumnHeaders.Add( , , "Bene/Servizio", 		50)

This.ColumnHeaders.Add( , , "Commessa", 				60)



This.FullRowSelect = .T.



ENDPROC


*======================================================================

*** CLASS / OBJECT: LV_Iva2 (BaseClass: olecontrol, Parent: pgtotali) ***
*** PROPERTIES ***
Comment = "D0D38173-724E-440D-A731-73FBD5E367AE"

Top = 256

Left = 25

Height = 74

Width = 573

Anchor = 90

Name = "LV_Iva2"


*** METHODS ***
PROCEDURE Refresh

Lparameters lForce



Iif(lForce, This.Load(), .T.)

ENDPROC

PROCEDURE Init

DoDefault()



** Add the ListView ColumnHeaders

This.ColumnHeaders.Add( , , TX_(, "5FFA51D6-EED5-48B3-ADED-5DEC7D5ED98C", "Aliquota"), 			50)

This.ColumnHeaders.Add( , , TX_(, "CD0F039F-2EE7-4746-A90A-B145F81A1D46", "VL"), 					20)

This.ColumnHeaders.Add( , , TX_(, "21D9DAF9-661B-4C49-BB30-E59A5B746004", "Imponibile"), 			70, 1)

This.ColumnHeaders.Add( , , TX_(, "42738497-F6E4-4B38-BA32-96392089119D", "Imposta"), 				70, 1)

This.ColumnHeaders.Add( , , TX_(, "967662EB-EBA0-47B4-8485-8BEBDC36B99B", "RC"), 					30)

This.ColumnHeaders.Add( , , TX_(, "D3C2C191-B572-4F71-9D21-11AFD3E35CE0", "Conto"), 				70)

This.ColumnHeaders.Add( , , TX_(, "496858E6-45AF-4CD4-B9C0-6B9BB7C6B971", "Commessa"), 			60)



This.FullRowSelect = .T.



ENDPROC

PROCEDURE load

This.ListItems.Clear()



If !InList(DOTes.TipoDocumento, 'F', 'A', 'N')



	Select crIva

	Scan

		oItem = This.ListItems.Add(, , Aliquota)

		oItem.SubItems(1) = Nvl(VL, '')

		oItem.SubItems(2) = Ltrim(Transform(Imponibile, This.Parent.PicSep))

		oItem.SubItems(3) = Ltrim(Transform(Imposta, 	 This.Parent.PicSep))

		oItem.SubItems(4) = Nvl(RC, '')

		oItem.SubItems(5) = Nvl(Conto, '')

		oItem.SubItems(6) = Nvl(Sottocommessa, '')

	EndScan 



EndIf 

ENDPROC


*======================================================================

*** CLASS / OBJECT: LV_Tot (BaseClass: olecontrol, Parent: pgtotali) ***
*** PROPERTIES ***
Comment = "71BF5399-BE12-4963-BFD4-C85838948F68"

Top = 1

Left = 25

Height = 184

Width = 573

Enabled = .F.

Anchor = 10

Name = "LV_Tot"


*** METHODS ***
PROCEDURE Refresh

Lparameters lForce



If lForce

	This.Load()

EndIf 

ENDPROC

PROCEDURE MouseMove

Lparameters button, shift, x, y



oSubItem = This.SubItemHitTest(x, y)



** Non funziona :-(

**	If oSubItem.Flags = 4 And oSubItem.SubItem = 8 And Left(This.ListItems(oSubItem.Item+1).Key, 3) = 'Rev'

**		If This.MousePointer != 99

**			This.MousePointer = 99  && 99 ccCustom

**		EndIf

**	Else

**		If This.MousePointer != 0

**			This.MousePointer = 0   && default

**		EndIf 

**	EndIf



If (oSubItem.Item = 0 And oSubItem.SubItem = 6 And This.ListItems(oSubItem.Item+1).SubItems(6) != '') && Sono sopra il link "Mostra in ..."

	SetCursor(This.hCursorHand)

Else

	SetCursor(This.hCursorNorm) 

EndIf

ENDPROC

PROCEDURE Click

Local oItem, oSubItem

Local nButton, nShift, nX, nY



nButton	= This.MouseUp_Button

nShift	= This.MouseUp_Shift

nX			= This.MouseUp_X

nY			= This.MouseUp_Y



oItem 	= This.xHitTest(nX, nY)

oSubItem = This.SubItemHitTest(nX, nY)



Do Case 

	Case oSubItem.Flags = 1	&& NoWhere

		Return

	

	Case oSubItem.Flags = 2 Or oSubItem.Flags = 4	&& OnItemIcon + OnItemLabel

		

		If oSubItem.SubItem = 0

		

			If nButton = 1  && Left Button

				This.OnClick     (oItem, nShift)

				Return

			EndIf



			If nButton = 2 	&& Right Button

				This.OnRightClick(oItem, nShift)

			EndIf

		

		Else

			** Click on SubItem	



			** Left Button on "Mostra in ..."

			If oSubItem.Item = 0 And oSubItem.SubItem = 6 And nButton = 1  



				This.Parent.CurrentVL = Iif(This.Parent.CurrentVL = 'EUR', 'VAL', 'EUR')

				This.Parent.Refresh()



				Return

			EndIf

		

		EndIf 



	Case oSubItem.Flags = 8	&& OnItemStateIcon 

		

EndCase 



ENDPROC

PROCEDURE Init

DoDefault()



** Add the ListView ColumnHeaders

This.ColumnHeaders.Add( , , "",  70)

This.ColumnHeaders.Add( , , "",  70, 1)

This.ColumnHeaders.Add( , , "",  70, 1)

This.ColumnHeaders.Add( , , "",  10)

This.ColumnHeaders.Add( , , "",  70)

This.ColumnHeaders.Add( , , "",  70, 1)

This.ColumnHeaders.Add( , , "", 110, 1)



** Supporto per customDraw e font-changing

This.AddProperty('hOldFont',  0)		&& devo salvare il font selezionato nel DC quando lo vario per ripristinarlo nel CustomDraw_PostXxx

This.AddProperty('hNewFontI', 0)		&& hfont clonato dal DC on attributo Italic     On

This.AddProperty('hNewFontU', 0)		&& hfont clonato dal DC on attributo Underlined On



This.AddProperty('hCursorNorm', LoadCursor(0, 32512)	)	&& #define IDC_ARROW MAKEINTRESOURCE(32512)  in WinUser.h

This.AddProperty('hCursorHand', LoadCursor(0, 32649)	)	&& #define IDC_HAND 	MAKEINTRESOURCE(32649)  in WinUser.h



This.CustomDraw_Enable(2)

ENDPROC

PROCEDURE load

Local oTotali

Local cPicSep



&& In modalità Show visualizzo i totali effettivi da DOTotali

If Thisform.Mode = FEDIMODE_SHOW

	Select DoTes

	Scatter Name oTotali

Else

	oTotali = Thisform.TotaleDocumento()

EndIf



AddProperty(oTotali, 'VL', 			  Iif(This.Parent.CurrentVL = 'EUR', 'EUR', 						 DOTes.Cd_VL				 ))

AddProperty(oTotali, 'TotMerceNetto', Iif(This.Parent.CurrentVL = 'EUR', oTotali.TotMerceNettoE, oTotali.TotMerceNettoV))

AddProperty(oTotali, 'TotMerceLordo', Iif(This.Parent.CurrentVL = 'EUR', oTotali.TotMerceLordoE, oTotali.TotMerceLordoV))

AddProperty(oTotali, 'TotSconto'    , Iif(This.Parent.CurrentVL = 'EUR', oTotali.TotScontoE    , oTotali.TotScontoV    ))

AddProperty(oTotali, 'TotSpese'     , Iif(This.Parent.CurrentVL = 'EUR', oTotali.TotSpeseE     , oTotali.TotSpeseV     ))

AddProperty(oTotali, 'TotOmaggio_M' , Iif(This.Parent.CurrentVL = 'EUR', oTotali.TotOmaggio_ME , oTotali.TotOmaggio_MV )) 

AddProperty(oTotali, 'TotOmaggio_I' , Iif(This.Parent.CurrentVL = 'EUR', oTotali.TotOmaggio_IE , oTotali.TotOmaggio_IV ))

AddProperty(oTotali, 'TotImponibile', Iif(This.Parent.CurrentVL = 'EUR', oTotali.TotImponibileE, oTotali.TotImponibileV))

AddProperty(oTotali, 'TotEsente'    , Iif(This.Parent.CurrentVL = 'EUR', oTotali.TotEsenteE    , oTotali.TotEsenteV    ))

AddProperty(oTotali, 'Abbuono'      , Iif(This.Parent.CurrentVL = 'EUR', oTotali.AbbuonoE      , oTotali.AbbuonoV      ))

AddProperty(oTotali, 'Acconto'      , Iif(This.Parent.CurrentVL = 'EUR', oTotali.AccontoE      , oTotali.AccontoV      ))

AddProperty(oTotali, 'RitCond'      , Iif(This.Parent.CurrentVL = 'EUR', oTotali.RA_ImportoE   , oTotali.RA_ImportoV   ))

AddProperty(oTotali, 'TotImposta'   , Iif(This.Parent.CurrentVL = 'EUR', oTotali.TotImpostaE   , oTotali.TotImpostaV   ))

AddProperty(oTotali, 'TotImpostaRC' , Iif(This.Parent.CurrentVL = 'EUR', oTotali.TotImpostaRCE , oTotali.TotImpostaRCV ))

AddProperty(oTotali, 'TotDocumento' , Iif(This.Parent.CurrentVL = 'EUR', oTotali.TotDocumentoE-oTotali.Arrotondamento, oTotali.TotDocumentoV ))

AddProperty(oTotali, 'TotAPagare'   , Iif(This.Parent.CurrentVL = 'EUR', oTotali.TotAPagareE  -oTotali.Arrotondamento, oTotali.TotAPagareV   ))



cPicSep = This.Parent.PicSep



This.HideColumnHeaders = .F.

This.ListItems.Clear()



** Prima riga

oItem = This.ListItems.Add(, , TX_(, "ECD64085-6F9C-48C8-A960-46B7519E4059", 'Valori in ') + oTotali.VL)

oItem.SubItems(1) = TX_(, "AE4B2D52-BE3E-4E64-82E0-16B7CFF1570D", 'Netto')

oItem.SubItems(2) = TX_(, "F71EEDF6-BD16-4FF3-8D83-342B4CD86E15", 'Lordo')

If DOTes.Cd_VL != 'EUR'

	oItem.SubItems(6) = Iif(This.Parent.CurrentVL = 'EUR', TX_(, "F3AA4605-D7BF-449D-8C29-EBC7E6FB9BB8", 'Mostra in valuta'), ;

																			 TX_(, "C148E83B-3063-4BD4-976D-5FD328D4D1A5", 'Mostra in EUR'))

Else

	oItem.SubItems(6) = ''

EndIf 



** Seconda riga

oItem = This.ListItems.Add(, , TX_(, "CD01E177-D9E5-4B09-8A31-5AE23841EB2F", 'Merce'))

oItem.SubItems(1) = Ltrim(Transform(oTotali.TotMerceNetto, cPicSep))

oItem.SubItems(2) = Ltrim(Transform(oTotali.TotMerceLordo, cPicSep))

oItem.SubItems(3) = ''

oItem.SubItems(4) = TX_(, "3AAC5D3B-E57B-4027-9F07-5163D0E11FA6", 'Sconto')

oItem.SubItems(5) = Ltrim(Transform(oTotali.TotSconto, cPicSep))

oItem.SubItems(6) = Iif(!IsEmpty(DoTes.ScontoCassa), '(%)  ' + Rtrim(DoTes.ScontoCassa), '')



** Terza riga

oItem = This.ListItems.Add(, , TX_(, "1D99C429-1048-43FD-AE71-7CFAC905F496", 'Spese'))

oItem.SubItems(1) = Ltrim(Transform(oTotali.TotSpese, cPicSep))

oItem.SubItems(2) = ''

oItem.SubItems(3) = ''

oItem.SubItems(4) = TX_(, "451B1D17-7B7F-44BD-92BD-AECBDB7D5B5D", 'Omaggio merce')

oItem.SubItems(5) = Ltrim(Transform(oTotali.TotOmaggio_M, cPicSep))

oItem.SubItems(6) = ''



** Quarta riga

oItem = This.ListItems.Add(, , '')

oItem.SubItems(1) = ''

oItem.SubItems(2) = TX_(, "A8B01EE3-0EC3-485B-AE31-529A7C1AC244", 'di cui esente')

oItem.SubItems(3) = ''

oItem.SubItems(4) = TX_(, "F692BED6-B1C1-468A-9F49-664BC573CB9E", 'Omaggio IVA')

oItem.SubItems(5) = Ltrim(Transform(oTotali.TotOmaggio_I, cPicSep))

oItem.SubItems(6) = ''



** Quinta riga

oItem = This.ListItems.Add(, , TX_(, "38825CD5-A1CA-42F5-A86A-6FD0F81228CE", 'Imponibile'))

oItem.SubItems(1) = Ltrim(Transform(oTotali.TotImponibile, cPicSep))

oItem.SubItems(2) = Ltrim(Transform(oTotali.TotEsente, cPicSep))

oItem.SubItems(3) = ''

oItem.SubItems(4) = TX_(, "A16597FF-CEB3-447C-9ACB-BE290C838045", 'Abbuono')

oItem.SubItems(5) = Ltrim(Transform(oTotali.Abbuono, cPicSep))

oItem.SubItems(6) = ''



** Sesta riga

oItem = This.ListItems.Add(, , TX_(, "80C58F17-84C9-4E3A-94ED-50EA46E3B6ED", 'Imposta'))

oItem.SubItems(1) = Ltrim(Transform(oTotali.TotImposta, cPicSep))

oItem.SubItems(2) = ''

oItem.SubItems(3) = ''

oItem.SubItems(4) = TX_(, "F469B339-93E6-4F89-959B-78D77647EDE8", 'Rit. Cond.')

oItem.SubItems(5) = Ltrim(Transform(oTotali.RitCond, cPicSep))

oItem.SubItems(6) = ''



** Settima riga

oItem = This.ListItems.Add(, , Iif(oTotali.TotImpostaRCV != 0, TX_(, "7980DA29-D368-4968-81EA-6980B975893C", '  di cui RC'), ''))

oItem.SubItems(1) = Iif(oTotali.TotImpostaRCV != 0, '(' + Ltrim(Transform(oTotali.TotImpostaRCV, cPicSep)) + ')', '')

oItem.SubItems(2) = ''

oItem.SubItems(3) = ''

oItem.SubItems(4) = TX_(, "6B073271-2C99-4440-983C-D120DF443311", 'Acconto')

oItem.SubItems(5) = Ltrim(Transform(oTotali.Acconto, cPicSep))

oItem.SubItems(6) = ''



** Ottava riga

oItem = This.ListItems.Add(, , TX_(, "96E723F1-459C-407E-8A38-D129748E1D5B", 'Totale'))

oItem.SubItems(1) = Ltrim(Transform(oTotali.TotDocumento, cPicSep))

oItem.SubItems(2) = ''

oItem.SubItems(3) = ''

oItem.SubItems(4) = TX_(, "AD10EA52-8802-49D9-8794-7D561B649867", 'Netto a pagare')

oItem.SubItems(5) = Ltrim(Transform(oTotali.TotAPagare, cPicSep))

oItem.SubItems(6) = ''



** Nona riga

oItem = This.ListItems.Add(, , '')

oItem.SubItems(1) = ''

oItem.SubItems(2) = ''

oItem.SubItems(3) = ''

oItem.SubItems(4) = ''

oItem.SubItems(5) = ''

oItem.SubItems(6) = Iif(DoTes.IvaSplit, TX_(, "ECC84BA5-ECDA-4EBE-B1B5-A074797081E6", 'scissione pag. art. 17-ter'), '')





ENDPROC

PROCEDURE customdraw_drawsubitem

Lparameters nItem, nSubItem, hDC, nForeColor, nBackColor, lParam



** Inizializzazioni dei nuovi font una tantum; lo posso fare solo ora xché se lo faccio nell'init clono e modifico un font errato



If This.hNewFontU = 0

	This.hNewFontU = CloneDCFont(hDC, , ,1)	&& Clono il font del DC e ne cambio in ON solo l'attributo Underlined

EndIf		

If This.hNewFontI = 0

	This.hNewFontI = CloneDCFont(hDC, ,1, )	&& Clono il font del DC e ne cambio in ON solo l'attributo Italic

EndIf	



Local oItem

Local nRet

nRet = CDRF_DODEFAULT  &&	normalmente CDRF_DODEFAULT, ma se combio il font allora CDRF_DODEFAULT + CDRF_NEWFONT



oItem = This.ListItems(nItem+1)



Do Case

	Case 	(oItem.Index = 1 And InList(nSubItem, 0))	&& cella "Valori in ..."

		nForeColor = Rgb(128,0,0)

		nBackColor = Rgb(255,255,255)



	Case 	.F. && (oItem.Index = 1 And InList(nSubItem, 1, 2)) 

		*	Or;

		*	(oItem.Index = 2 And InList(nSubItem, 0, 4)) Or;

		*	(oItem.Index = 3 And InList(nSubItem, 0, 4)) Or;

		*	(oItem.Index = 4 And InList(nSubItem,    4)) Or;

		*	(oItem.Index = 5 And InList(nSubItem, 0, 4)) Or;

		*	(oItem.Index = 6 And InList(nSubItem, 0, 4)) Or;

		*	(oItem.Index = 8 And InList(nSubItem, 0, 4))



		nBackColor = Rgb(192,192,192)

		nForeColor = Rgb(255,255,255)

		

	Case oItem.Index = 1 And InList(nSubItem, 6)	&& Link VALUTA

		nForeColor = Rgb(0,0,225)

		This.hOldFont = SelectObject(hDC, This.hNewFontU)

		nRet = CDRF_DODEFAULT + CDRF_NEWFONT		



	Case 	(oItem.Index = 4 And InList(nSubItem, 2))		Or ;	&& cella "di cui esente"

			(oItem.Index = 1 And InList(nSubItem, 1, 2)) Or ;

			(oItem.Index = 2 And InList(nSubItem, 0, 4)) Or ;

			(oItem.Index = 3 And InList(nSubItem, 0, 4)) Or ;

			(oItem.Index = 4 And InList(nSubItem,    4)) Or ;

			(oItem.Index = 5 And InList(nSubItem, 0, 4)) Or ;

			(oItem.Index = 6 And InList(nSubItem, 0, 4)) Or ;

			(oItem.Index = 7 And InList(nSubItem, 0, 4)) Or ;

			(oItem.Index = 8 And InList(nSubItem, 0, 4))



		nBackColor = Rgb(252,252,252)

		nForeColor = Rgb(28,28,28)

		This.hOldFont = SelectObject(hDC, This.hNewFontI)

		nRet = CDRF_DODEFAULT + CDRF_NEWFONT



	Case 	(oItem.Index = 9 And InList(nSubItem, 6))	Or ;	&& cella "Scissione pagamenti"

			(oItem.Index = 7 And InList(nSubItem, 1))			&& Imposta RC

				

		This.hOldFont = SelectObject(hDC, This.hNewFontI)

		nRet = CDRF_DODEFAULT + CDRF_NEWFONT

		

	Otherwise 

		nBackColor = Rgb(255,255,255)

		nForeColor = Rgb(0,0,0)

Endcase 



Return nRet

ENDPROC

PROCEDURE Destroy

If This.hNewFontI != 0

	DeleteObject(This.hNewFontI)

EndIf

If This.hNewFontU != 0

	DeleteObject(This.hNewFontU)

EndIf





ENDPROC

PROCEDURE customdraw_postsubitemdraw

Lparameters nItem, nSubItem, hDC, nForeColor, nBackColor, lParam



If This.hOldFont != 0

	SelectObject(hDC, This.hOldFont)

	This.hOldFont = 0

EndIf

ENDPROC


*======================================================================

*** CLASS / OBJECT: LV_Provv (BaseClass: olecontrol, Parent: pgtotali) ***
*** PROPERTIES ***
Comment = "D0D38173-724E-440D-A731-73FBD5E367AE"

Top = 329

Left = 25

Height = 74

Width = 573

Anchor = 30

Name = "LV_Provv"


*** METHODS ***
PROCEDURE Refresh

Lparameters lForce



If lForce

	This.Load()

EndIf 

ENDPROC

PROCEDURE customdraw_drawsubitem

Lparameters nItem, nSubItem, hDC, nForeColor, nBackColor, lParam



** Inizializzazioni dei nuovi font una tantum; lo posso fare solo ora xché se lo faccio nell'init clono e modifico un font errato



If This.hNewFontB = 0

	This.hNewFontB = CloneDCFont(hDC, 1, ,)	&& Clono il font del DC e ne cambio in ON solo l'attributo Bold

EndIf		





Local oItem

Local nRet

nRet = CDRF_DODEFAULT  &&	normalmente CDRF_DODEFAULT, ma se combio il font allora CDRF_DODEFAULT + CDRF_NEWFONT



oItem = This.ListItems(nItem+1)



If Left(oItem.key, 1) = 'T'	&& Totali

	This.hOldFont = SelectObject(hDC, This.hNewFontB)

	nBackColor = oApp.ColorGridBackYellow 

	nRet = CDRF_DODEFAULT + CDRF_NEWFONT

Else

	nBackColor = Rgb(255,255,255)

EndIf



Return nRet

ENDPROC

PROCEDURE customdraw_postsubitemdraw

Lparameters nItem, nSubItem, hDC, nForeColor, nBackColor, lParam



If This.hOldFont != 0

	SelectObject(hDC, This.hOldFont)

	This.hOldFont = 0

EndIf

ENDPROC

PROCEDURE Destroy

If This.hNewFontB != 0

	DeleteObject(This.hNewFontB)

EndIf



ENDPROC

PROCEDURE load

Local nTotProvv

Local oItem

Local cVL



This.ListItems.Clear()



Select crProvv

Calculate Sum(ValoreProvv) To nTotProvv For Tipo = '1'

If !IsEmpty(nTotProvv)



	Scan For Tipo = '1'

		oItem = This.ListItems.Add(, , Transform(Riga))

		oItem.SubItems(1) = Rtrim(Nvl(Cd_AR, '')) + Iif(IsNull(Cd_AR), '', ' - ') + Rtrim(Nvl(Descrizione, ''))

		oItem.SubItems(2) = Rtrim(VL)

		oItem.SubItems(3) = Ltrim(Transform(PrezzoTotale, 	 '###,###,###.##'))

		oItem.SubItems(4) = Rtrim(Provv)

		oItem.SubItems(5) = Ltrim(Transform(ValoreProvv, 	 '###,###,###.##'))

		cVL = VL

	EndScan 



	oItem = This.ListItems.Add(, 'T1', '')

	oItem.SubItems(1) = TX_(, "89ADE3EC-10F4-4E7E-9E75-29C55C67F8A4", 'TOTALE AGENTE ') + Nvl(DoTes.Cd_Agente_1, '???')

	oItem.SubItems(2) = Rtrim(cVL)

	oItem.SubItems(5) = Ltrim(Transform(nTotProvv, 	 '###,###,###.##'))

EndIf 



Calculate Sum(ValoreProvv) To nTotProvv For Tipo = '2'

If !IsEmpty(nTotProvv)



	oItem = This.ListItems.Add(, , '')



	Scan For Tipo = '2'

		oItem = This.ListItems.Add(, , Transform(Riga))

		oItem.SubItems(1) = Rtrim(Nvl(Cd_AR, '')) + Iif(IsNull(Cd_AR), '', ' - ') + Rtrim(Nvl(Descrizione, ''))

		oItem.SubItems(2) = Rtrim(VL)

		oItem.SubItems(3) = Ltrim(Transform(PrezzoTotale, 	 '###,###,###.##'))

		oItem.SubItems(4) = Rtrim(Provv)

		oItem.SubItems(5) = Ltrim(Transform(ValoreProvv, 	 '###,###,###.##'))

		cVL = VL

	EndScan 



	oItem = This.ListItems.Add(, 'T2', '')

	oItem.SubItems(1) = TX_(, "3A1727AB-C51A-465D-84A4-B602E8084A0D", 'TOTALE AGENTE ') + Nvl(DoTes.Cd_Agente_2, '???')

	oItem.SubItems(2) = Rtrim(cVL)

	oItem.SubItems(5) = Ltrim(Transform(nTotProvv, 	 '###,###,###.##'))

EndIf 

ENDPROC

PROCEDURE Init

DoDefault()



** Add the ListView ColumnHeaders

This.ColumnHeaders.Add( , , TX_(, "73624283-A5ED-41BE-AED3-3987F29D06BC", "R"), 					15)

This.ColumnHeaders.Add( , , TX_(, "635A7283-ADAD-4B0C-80B3-EFAC08FFAC44", "Descrizione"),   140)

This.ColumnHeaders.Add( , , TX_(, "8A0EF36E-69A3-4A1F-B23D-9C216158CEEB", "VL"), 				20)

This.ColumnHeaders.Add( , , TX_(, "43E10A4E-2695-4703-A2A9-B2DCC88270BA", "Prezzo Totale"), 	70, 1)

This.ColumnHeaders.Add( , , TX_(, "CFF2B4C9-3B17-46DD-A04F-D2A2E8B3AB34", "% Provv"), 			40)

This.ColumnHeaders.Add( , , TX_(, "B0DEF674-1F96-4460-BF86-20785022493B", "Provvigioni"), 	70, 1)



This.FullRowSelect = .T.





** Supporto per customDraw e font-changing

This.AddProperty('hOldFont',  0)		&& devo salvare il font selezionato nel DC quando lo vario per ripristinarlo nel CustomDraw_PostXxx

This.AddProperty('hNewFontB', 0)		&& hfont clonato dal DC on attributo Bold     On



This.CustomDraw_Enable(2)



ENDPROC


*======================================================================

*** CLASS / OBJECT: cmb_statofte (BaseClass: combobox, Parent: ) ***
*** PROPERTIES ***
Name = "cmb_statofte"


*** METHODS ***
PROCEDURE When

Local cWhere



DoDefault()



If This.ListCount > 1

	Return 

EndIf 



cWhere = ICase(Thisform.DoBitMask = TD_TUTTO,					"", ;

					Bitand(TD_CA_TUTTO, Thisform.DoBitMask) > 0, " And CicloAttivoPassivo = 'A'", ;

					Bitand(TD_CP_TUTTO, Thisform.DoBitMask) > 0, " And CicloAttivoPassivo = 'P'", ;

																				"")

xSqlExec('Select Bar_Caption From FTE_WorkFlow Where Bar_Caption Is Not Null' + cWhere, 'statiFTE')



Scan

	With This

		.AddItem(StatiFTE.Bar_Caption)

		.List(.ListCount, 2) = Rtrim(StatiFTE.Bar_Caption)

	EndWith 

EndScan 



Use In statiFTE

ENDPROC


*======================================================================

*** CLASS / OBJECT: cmb_statofactoring (BaseClass: combobox, Parent: ) ***
*** PROPERTIES ***
Name = "cmb_statofactoring"


*** METHODS ***
PROCEDURE When

DoDefault()



If This.ListCount > 1

	Return 

EndIf 



With This

	.AddItem('Da confermare')

	.List(.ListCount, 2) = 'CONF'



	.AddItem('In istruttoria')

	.List(.ListCount, 2) = 'ISTR'



	.AddItem('In attesa erogazione')

	.List(.ListCount, 2) = 'INER'



	.AddItem('Credito erogato')

	.List(.ListCount, 2) = 'EROG'



	.AddItem('In sospeso')

	.List(.ListCount, 2) = 'AREN'



EndWith 



ENDPROC


*======================================================================

*** CLASS / OBJECT: elenco (BaseClass: container, Parent: ) ***
*** PROPERTIES ***
Width = 793

Height = 207

repoform = Repo_Doc

Name = "elenco"

Grid.ColumnCount = 36

Grid.Colbase1.Comment = "EB298DF7-F1A9-4D2B-B822-FF8C285FF927"

Grid.Colbase1.FontSize = 8

Grid.Colbase1.ControlSource = "DoTes.Id_DoTes"

Grid.Colbase1.Width = 64

Grid.Colbase1.Name = "ColId_DoTes"

Grid.Colbase2.Comment = "F0E02032-1170-4762-B61F-7F7EC39A4216"

Grid.Colbase2.FontSize = 8

Grid.Colbase2.ControlSource = "DoTes.EsAnno"

Grid.Colbase2.Width = 30

Grid.Colbase2.Name = "ColEsercizio"

Grid.Colbase3.Comment = "9ABC3877-898A-4217-B64F-692352D7899A"

Grid.Colbase3.FontSize = 8

Grid.Colbase3.ControlSource = "Decode_TipoDO(DOTes.TipoDocumento)"

Grid.Colbase3.Width = 81

Grid.Colbase3.Name = "ColTipoDocumento"

Grid.Colbase4.Comment = "A8600DFB-657E-48E9-8DF6-190892988B49"

Grid.Colbase4.FontSize = 8

Grid.Colbase4.ControlSource = "DoTes.Cd_Do"

Grid.Colbase4.Width = 26

Grid.Colbase4.Format = "!"

Grid.Colbase4.Name = "ColCd_Do"

Grid.Colbase5.Comment = "50FBEE65-3FC0-4F5E-8C11-F585738A6076"

Grid.Colbase5.FontName = "Courier New"

Grid.Colbase5.FontSize = 8

Grid.Colbase5.ControlSource = "DoTes.NumeroDoc"

Grid.Colbase5.Width = 60

Grid.Colbase5.Name = "ColNumeroDoc"

Grid.Colbase6.Comment = "04A6E993-EBE0-40BB-B966-3A5BE578E56E"

Grid.Colbase6.FontSize = 8

Grid.Colbase6.ControlSource = "TTOD(DOTes.DataDoc)"

Grid.Colbase6.Width = 63

Grid.Colbase6.Name = "ColDataDoc"

Grid.Colbase7.Comment = "B98317DD-2259-4764-AC0E-271D6504451B"

Grid.Colbase7.FontName = "Courier New"

Grid.Colbase7.FontSize = 8

Grid.Colbase7.ControlSource = "DoTes.NumeroDocRif"

Grid.Colbase7.Width = 60

Grid.Colbase7.Name = "ColNumeroDocRif"

Grid.Colbase8.Comment = "27EC60E7-8F45-4F46-BB3A-EB655F6B004E"

Grid.Colbase8.FontSize = 8

Grid.Colbase8.ControlSource = "TTOD(DoTes.DataDocRif)"

Grid.Colbase8.Width = 63

Grid.Colbase8.Name = "ColDataDocRif"

Grid.Colbase9.Comment = "8623B266-D9C8-48F9-ABCE-062BA556F6D5"

Grid.Colbase9.FontSize = 8

Grid.Colbase9.ControlSource = "DoTes.Cd_CF_R"

Grid.Colbase9.Width = 54

Grid.Colbase9.Format = "!"

Grid.Colbase9.Name = "ColCF"

Grid.Colbase10.Comment = "832BEB26-60CE-47A7-96B3-D99B65D86F1E"

Grid.Colbase10.FontSize = 8

Grid.Colbase10.ControlSource = "DoTes.CFDesc_R"

Grid.Colbase10.Width = 200

Grid.Colbase10.Name = "ColCFDesc"

Grid.Colbase11.Comment = "BF7F255E-36BE-4043-9233-DB3188EA91DC"

Grid.Colbase11.FontSize = 8

Grid.Colbase11.ControlSource = "DoTes.Cd_CFDest"

Grid.Colbase11.Width = 39

Grid.Colbase11.Format = "!"

Grid.Colbase11.Name = "ColCd_CFDest"

Grid.Colbase12.Comment = "BFED85E6-C580-4150-9DB5-78243C4CE484"

Grid.Colbase12.FontSize = 8

Grid.Colbase12.ControlSource = "DoTes.Cd_CN + ' ' + DOTes.CNDesc"

Grid.Colbase12.Width = 150

Grid.Colbase12.Format = ""

Grid.Colbase12.Name = "ColContatore"

Grid.Colbase13.Comment = "BC5E221B-8322-4178-8C44-E3B578E5D017"

Grid.Colbase13.FontSize = 8

Grid.Colbase13.ControlSource = "DoTes.Cd_Agente_1"

Grid.Colbase13.Width = 73

Grid.Colbase13.Format = "!"

Grid.Colbase13.Name = "ColCd_Agente_1"

Grid.Colbase14.Comment = "4CEB2085-5DCF-4D07-9C10-0050BFAA54EB"

Grid.Colbase14.FontSize = 8

Grid.Colbase14.ControlSource = "DoTes.Agente_1_Descrizione"

Grid.Colbase14.Width = 150

Grid.Colbase14.Name = "ColAgente_1_Descrizione"

Grid.Colbase15.Comment = "D410FF2B-4232-442A-8BCA-2C45E5787213"

Grid.Colbase15.FontSize = 8

Grid.Colbase15.ControlSource = "DoTes.Cd_Agente_2"

Grid.Colbase15.Width = 73

Grid.Colbase15.Name = "ColCd_Agente_2"

Grid.Colbase16.Comment = "AF437AE9-750D-4576-BC8A-E1BBDE5F2656"

Grid.Colbase16.FontSize = 8

Grid.Colbase16.ControlSource = "DoTes.Agente_2_Descrizione"

Grid.Colbase16.Width = 150

Grid.Colbase16.Name = "ColAgente_2_Descrizione"

Grid.Colbase17.Comment = "9B661618-0880-4C77-A2F8-E197E2E4057F"

Grid.Colbase17.FontSize = 8

Grid.Colbase17.ControlSource = "DoTes.Cd_VL"

Grid.Colbase17.Width = 35

Grid.Colbase17.Format = "!"

Grid.Colbase17.Name = "ColCd_VL"

Grid.Colbase18.Comment = "653A710F-2EA7-4EC7-A7DB-2450E422471B"

Grid.Colbase18.FontSize = 8

Grid.Colbase18.ControlSource = "DoTes.Cambio"

Grid.Colbase18.Width = 39

Grid.Colbase18.DynamicInputMask = "THIS.DynamicInputMask()"

Grid.Colbase18.InputMask = "####.###"

Grid.Colbase18.Name = "ColCambio"

Grid.Colbase19.Comment = "D66BAE0F-2CC7-4A00-ABEE-6C43963D9553"

Grid.Colbase19.FontSize = 8

Grid.Colbase19.ControlSource = "DoTes.Cd_PG"

Grid.Colbase19.Width = 57

Grid.Colbase19.Format = "!"

Grid.Colbase19.Name = "ColCd_PG"

Grid.Colbase20.Comment = "46800FE0-6106-4781-9410-BC38CD6E94FF"

Grid.Colbase20.FontSize = 8

Grid.Colbase20.ControlSource = "DoTes.Cd_LS_1"

Grid.Colbase20.Width = 44

Grid.Colbase20.Format = "!"

Grid.Colbase20.Name = "ColCd_LS_1"

Grid.Colbase21.Comment = "DEF357AC-BFDE-4BDB-B39D-FD7B513728D5"

Grid.Colbase21.FontSize = 8

Grid.Colbase21.ControlSource = "DoTes.Cd_LS_2"

Grid.Colbase21.Width = 44

Grid.Colbase21.Format = "!"

Grid.Colbase21.Name = "ColCd_LS_2"

Grid.Colbase22.Comment = "6FB74248-80C7-4118-BED1-201533739584"

Grid.Colbase22.FontSize = 8

Grid.Colbase22.ControlSource = "DoTes.Cd_DoSottocommessa"

Grid.Colbase22.Width = 81

Grid.Colbase22.Format = "!"

Grid.Colbase22.Name = "Colcd_DOCommessa"

Grid.Colbase23.Comment = "315B8958-619C-4121-8003-77AC66C01FB8"

Grid.Colbase23.FontSize = 8

Grid.Colbase23.ControlSource = "DoTes.Righe"

Grid.Colbase23.Width = 31

Grid.Colbase23.InputMask = "####"

Grid.Colbase23.Name = "ColRighe"

Grid.Colbase24.Comment = "98C5750B-F92F-4785-A46A-74D819D20B97"

Grid.Colbase24.FontSize = 8

Grid.Colbase24.ControlSource = "DoTes.RigheEvadibili"

Grid.Colbase24.Width = 46

Grid.Colbase24.InputMask = "####"

Grid.Colbase24.Name = "ColRigheEvadibili"

Grid.Colbase25.Comment = "A6B9C770-85DF-47E5-A489-ACFB76ED368D"

Grid.Colbase25.FontSize = 8

Grid.Colbase25.ControlSource = "DoTes.AccontoV"

Grid.Colbase25.Width = 45

Grid.Colbase25.InputMask = "###,###,###.###"

Grid.Colbase25.Name = "ColAccontoV"

Grid.Colbase26.Comment = "02249796-0981-41A4-9BEC-AC136C817D5E"

Grid.Colbase26.FontSize = 8

Grid.Colbase26.ControlSource = "DoTes.AbbuonoV"

Grid.Colbase26.Width = 48

Grid.Colbase26.InputMask = "###,###,###.###"

Grid.Colbase26.Name = "ColAbbuonoV"

Grid.Colbase27.Comment = "FD9B2137-D9C5-4AD9-AA9D-5EDAB3672B79"

Grid.Colbase27.FontSize = 8

Grid.Colbase27.ColumnOrder = 27

Grid.Colbase27.ControlSource = "DoTes.TotDocumentoV"

Grid.Colbase27.Width = 89

Grid.Colbase27.InputMask = "###,###,###,###.###"

Grid.Colbase27.ToolTipText = "Totale Documento in Valuta"

Grid.Colbase27.Name = "ColTotDocumentoV"

Grid.Colbase28.Comment = "3F9160A6-AE0A-460A-92FC-E74EAFDE5E8D"

Grid.Colbase28.FontSize = 8

Grid.Colbase28.Alignment = 2

Grid.Colbase28.ColumnOrder = 29

Grid.Colbase28.ControlSource = "Decode_Logico(DoTes.Esecutivo, .t.)"

Grid.Colbase28.Width = 20

Grid.Colbase28.ToolTipText = "Esecutivo"

Grid.Colbase28.Name = "ColEsecutivo"

Grid.Colbase29.Comment = "C15D9A73-86AC-4F5F-9B36-230D91F1D454"

Grid.Colbase29.FontSize = 8

Grid.Colbase29.Alignment = 2

Grid.Colbase29.ColumnOrder = 30

Grid.Colbase29.ControlSource = "Decode_Logico(DoTes.Prelevabile, .t.)"

Grid.Colbase29.Width = 20

Grid.Colbase29.ToolTipText = "Prelevabile"

Grid.Colbase29.Name = "ColPrelevabile"

Grid.Colbase30.Comment = "8EB3FB48-E9D2-4578-961B-1CD9EC9F0E54"

Grid.Colbase30.FontSize = 8

Grid.Colbase30.Alignment = 2

Grid.Colbase30.ColumnOrder = 31

Grid.Colbase30.ControlSource = "Decode_Logico(DoTes.Modificabile, .t.)"

Grid.Colbase30.Width = 20

Grid.Colbase30.ToolTipText = "Modificabile"

Grid.Colbase30.Name = "ColModificabile"

Grid.Colbase31.Comment = "DC7CDD65-B482-454C-A8E5-98717EB07F76"

Grid.Colbase31.FontSize = 8

Grid.Colbase31.ColumnOrder = 32

Grid.Colbase31.ControlSource = "Decode_Logico(DoTes.IvaSospesa, .t.)"

Grid.Colbase31.Width = 21

Grid.Colbase31.ToolTipText = "IVA ad esigibilità differita"

Grid.Colbase31.Name = "ColIvaSospesa"

Grid.Colbase32.Comment = "6E8041C2-C8C5-4CE6-8F87-B95682519F7A"

Grid.Colbase32.FontSize = 8

Grid.Colbase32.ColumnOrder = 33

Grid.Colbase32.ControlSource = "Decode_Logico(DoTes.OC_Scaduto, .T.)"

Grid.Colbase32.Width = 44

Grid.Colbase32.Name = "Col_OCScaduto"

Grid.Colbase33.Comment = "93233679-DB32-48ED-891E-D18972E2B031"

Grid.Colbase33.FontSize = 8

Grid.Colbase33.ColumnOrder = 28

Grid.Colbase33.ControlSource = "DoTes.TotaPagareV"

Grid.Colbase33.Width = 89

Grid.Colbase33.InputMask = "###,###,###,###.###"

Grid.Colbase33.ToolTipText = "Netto a pagare in valuta"

Grid.Colbase33.Name = "ColNettoaPagare"

Grid.Colbase34.FontSize = 8

Grid.Colbase34.ControlSource = "Dotes.StatoFte"

Grid.Colbase34.Width = 74

Grid.Colbase34.Name = "Col_statoFte"

Grid.Colbase35.Comment = "CBDAD05C-7D94-4979-96C1-A5BFF9C24871"

Grid.Colbase35.FontSize = 8

Grid.Colbase35.Alignment = 2

Grid.Colbase35.ControlSource = "DOTES.Attributi"

Grid.Colbase35.Width = 44

Grid.Colbase35.ReadOnly = .T.

Grid.Colbase35.Sparse = .F.

Grid.Colbase35.DynamicCurrentControl = "Iif(IsEmpty(DoTes.Attributi), 'Attributi_None', 'Attributi_image')"

Grid.Colbase35.Name = "colAttributi"

Grid.Colbase36.FontSize = 8

Grid.Colbase36.ControlSource = "DoTes.FactoringStatus"

Grid.Colbase36.Width = 110

Grid.Colbase36.Name = "colFactoring"

Grid.Comment = "1A53DEDE-6C72-41B5-98B3-F516A2B47FFB"

Grid.FontSize = 8

Grid.Height = 187

Grid.Left = 0

Grid.Panel = 1

Grid.RecordSource = "DoTes"

Grid.RowHeight = 17

Grid.Top = 0

Grid.Width = 793

Grid.Name = "Grid"


*** METHODS ***
PROCEDURE onfiltercontrolvalid

Lparameters oCtrl



If oCtrl.Parent = This.FilterGrid.ColNumeroDoc

	If At('%', oCtrl.Value) = 0

		oCtrl.Value = NormNumDoc(oCtrl.Value)

	EndIf 

EndIf



Return .T.

	





ENDPROC

PROCEDURE showfiltergrid

Lparameters lShow



If lShow And This.HasFilterGrid = .F.

	DoDefault(lShow)

	This.FilterGrid.ColTipoDocumento.Controls[2].DoBitMask = Thisform.De.DoBitMask

Else

	DoDefault(lShow)

Endif

ENDPROC

PROCEDURE Init

LParameters nHostedBy, nParentWidth, nParentHeight, lSetAutoSize



Local nDoBitMask



If !DoDefault(nHostedBy, nParentWidth, nParentHeight, lSetAutoSize)

	Return .F.

EndIf 



** IVA Sospesa

nDoBitMask = Iif(PemStatus(Thisform, 'DoBitMask', 5), Thisform.DoBitMask, TD_TUTTO)			&& nella finestra di ricerca non c'è la property DOBitMask

This.LblLegend02a			.Visible = BitAnd(TD_DOCIVA, nDoBitMask) != 0

This.LblLegend02b			.Visible = This.lblLegend02a.Visible

This.Grid.colIvaSospesa	.Visible = This.lblLegend02a.Visible



ENDPROC

PROCEDURE Grid.Col_OCScaduto.Init

DoDefault()



If PemStatus(Thisform, 'DoBitMask', 5)

	This.Visible = Bitand(Thisform.DoBitMask, TD_CA_ORDINE + TD_CP_ORDINE ) != 0

EndIf 



ENDPROC

PROCEDURE Grid.Col_statoFte.Init

This.AddProperty('SpcComboClass',			'cmb_statofte')

This.AddProperty('SpcComboClassLibrary',	'forms\fedi_doc.vcx')



Return DoDefault()

ENDPROC

PROCEDURE Grid.colAttributi.Init

This.AddProperty('SpcComboClass', 			'Attributi_Flt_Elenco')

This.AddProperty('SpcComboClassLibrary',  'Libs\Attributi.vcx')

This.AddProperty('SpcComboClassParms',    "'DOTES'"					)		&& i parametri verranno macrocompilati: per questo ci sono "" con dentro ''



Return DoDefault()

ENDPROC

PROCEDURE Grid.colFactoring.Init

This.AddProperty('SpcComboClass',			'cmb_statofactoring')

This.AddProperty('SpcComboClassLibrary',	'forms\fedi_doc.vcx')



Return DoDefault()

ENDPROC

PROCEDURE Grid.layoutset

Lparameters cLayoutInfo



** Non ci sono impostazioni per la colonna ColAttributi: è la prima volta che viene aggiunta, la posiziono con un default 

DoDefault(cLayoutInfo)

If Atc('ColAttributi', cLayoutInfo) = 0

 	This.SetColumnOrder(This.ColAttributi,  1)

Endif

ENDPROC

PROCEDURE Grid.dynamicbackcolor

Return Icase( !DoTes.Esecutivo,  This.Parent.lblLegend06a.BackColor, ;

					DoTes.OC_Scaduto, This.Parent.lblLegend07a.BackColor, ;					

																		oApp.ColorWindow)

ENDPROC

PROCEDURE Grid.Init

DoDefault()

This.SetAll('DynamicForeColor', 'This.DynamicForeColor()')

This.SetAll('DynamicBackColor', 'This.DynamicBackColor()')



** In seguito all'ibridazione della colonna cli/for che punta ad un campo calcolato nell'init del dotes CD_CF_R = ISNULL(DOTES.CD_CF_AUTO, DOTES.CD_CF)

** la func IsEleColSearchable() non riconosce il campo come valido in quanto NON collegato a FK per cui non popola la FKSELECT della colonna e viene disabilitata la voce del context menu "FILTRA PER ..."

AddProperty(This.ColCF, 'FKSelect', This.ColCF.Text1.FKSelect)



** ----- LICADAPTER

If !oApp.LicInfo.Commesse

	This.colCd_DOCommessa.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

EndIf

If !oApp.LicInfo.DO_Factoring Or !oApp.oUser.AccessFactoring Or !PemStatus(Thisform, 'DOBitMask', 5) Or !InList(Thisform.DOBitMask, 0x0000000008, 0x0000000010)

	This.colFactoring.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

EndIf



If xSqlExec2Var("If Exists(Select * From Attributo Where UsedBy = 'DOTES') Select 1 Else Select 0") = 0

	This.ColAttributi.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

EndIf





ENDPROC

PROCEDURE Grid.dynamicforecolor

**	RETURN IIF(DoTes.RigheEvadibili=0, ;

**				  IIF(DoTes.TipoDocumento $ 'FNA', oApp.ColorGridForeRED, oApp.ColorGridForeBLU), ;

**				  oApp.ColorWindowText)



Return ICase(;

		 	DoTes.RigheEvadibili = 0,	This.Parent.lblLegend01a.BackColor, ;			&& Evaso

		 	DoTes.IvaSospesa,				This.Parent.lblLegend02a.BackColor, ;			&& Fatture con iva sospesa

												oApp.ColorWindowText)



ENDPROC

PROCEDURE Grid.dynamicinputmask

RETURN DOTes.PicSep



ENDPROC

PROCEDURE Grid.oncolumnheaderclick

Lparameters oCol

DoDefault(oCol)



** SAS 4041 - Abilito/disabilito i bottoni della toolbar dopo che è stato fatto un ordinamento di colonne e cambia il record corrente

ThisForm.OnRecordChange()



ENDPROC


*======================================================================

*** CLASS / OBJECT: lblLegend02a (BaseClass: label, Parent: elenco) ***
*** PROPERTIES ***
Comment = "989EDCDA-ED3B-4B5A-A2B7-72E925D63939"

Anchor = 4

BackStyle = 1

BorderStyle = 1

Caption = ""

Height = 12

Left = 64

Top = 191

Width = 12

TabIndex = 17

ZOrderSet = 2

ToolTipText = "Anagrafica soggetta ad applicabilità dell'iva con esigibilità differita"

Name = "lblLegend02a"


*** METHODS ***
PROCEDURE Init

This.BackColor = oApp.Color.Coral

DoDefault()

ENDPROC


*======================================================================

*** CLASS / OBJECT: lblLegend06a (BaseClass: container, Parent: elenco) ***
*** PROPERTIES ***
Anchor = 12

Top = 190

Left = 711

Width = 80

Height = 15

BackStyle = 1

Name = "lblLegend06a"


*** METHODS ***
PROCEDURE Init

DoDefault()

This.BackColor = oApp.Color.Beige

ENDPROC


*======================================================================

*** CLASS / OBJECT: lblLegend06a (BaseClass: container, Parent: pgrighe) ***
*** PROPERTIES ***
Anchor = 12

Top = 277

Left = 662

Width = 61

Height = 15

BackStyle = 1

Name = "lblLegend06a"


*** METHODS ***
PROCEDURE Init

This.BackColor = oApp.ColorInfoBK

DoDefault()



ENDPROC


*======================================================================

*** CLASS / OBJECT: lblLegend01a (BaseClass: label, Parent: elenco) ***
*** PROPERTIES ***
Comment = "1EAB23EF-434D-40AE-B5BB-CADF793E4838"

Anchor = 4

BackStyle = 1

BorderStyle = 1

Caption = ""

Height = 12

Left = 3

Top = 191

Visible = .T.

Width = 12

TabIndex = 16

ZOrderSet = 5

Name = "lblLegend01a"


*** METHODS ***
PROCEDURE Init

This.BackColor = oApp.ColorGridForeBlu

DoDefault()



ENDPROC


*======================================================================

*** CLASS / OBJECT: lblLegend07a (BaseClass: container, Parent: elenco) ***
*** PROPERTIES ***
Anchor = 12

Top = 190

Left = 620

Width = 88

Height = 15

BackStyle = 1

Name = "lblLegend07a"


*** METHODS ***
PROCEDURE Init

DoDefault()

This.BackColor = oApp.Color.MistyRose



If PemStatus(Thisform, 'DoBitMask', 5)

	This.Visible = Bitand(Thisform.DoBitMask, TD_CA_ORDINE + TD_CP_ORDINE ) != 0

EndIf  



ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: detail.PF.pgGenerale.txtMatricole.Grid.ColMatricola) ***
*** PROPERTIES ***
Comment = "04E60BA4-8BD3-49DC-8E0B-23DB8D9E1D1E"

FontSize = 8

BorderStyle = 0

Margin = 0

SelectOnEntry = .F.

Name = "Text1"


*** METHODS ***
PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)

ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: detail.PF.pgGenerale.txtPackingList.Grid.ColElemento) ***
*** PROPERTIES ***
Comment = "8CD7ABFF-191C-4AA8-AACF-819F4245AA82"

FontSize = 8

Seconds = 2

BorderStyle = 0

Margin = 0

SelectOnEntry = .F.

TabIndex = 1

Name = "Text1"


*** METHODS ***
PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)

ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: detail.PF.pgGenerale.txtPackingList.Grid.ColQta) ***
*** PROPERTIES ***
Comment = "B9254795-FA17-455E-83D8-76F0CC33BC68"

FontSize = 8

Seconds = 2

BorderStyle = 0

Margin = 0

SelectOnEntry = .F.

TabIndex = 1

Name = "Text1"


*** METHODS ***
PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)

ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: pgrighe.Grid.ColRiga) ***
*** PROPERTIES ***
Comment = "16CCD85D-A710-4DA2-ACCE-5A96A7975BFA"

FontSize = 8

BorderStyle = 0

Enabled = .F.

Margin = 0

Name = "Text1"


*** METHODS ***
PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif

Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: pgrighe.Grid.ColDescrizione) ***
*** PROPERTIES ***
Comment = "43678E36-C6CB-4E56-8F1D-ABD7934EF1A0"

FontSize = 8

BorderStyle = 0

Margin = 0

Name = "Text1"


*** METHODS ***
PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif

Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: pgrighe.Grid.ColCd_ARMisura) ***
*** PROPERTIES ***
FontSize = 8

BorderStyle = 0

Margin = 0

Top = 11

Width = 25

fktabledesc = Unità di misura

fkdecodedfield = Descrizione

Name = "Text1"


*** METHODS ***
PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif

Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC

PROCEDURE fkgetcodar

Return DoRig.Cd_AR





ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: pgrighe.Grid.ColFattoreToUM1) ***
*** PROPERTIES ***
Comment = "6AC258CE-69B3-4768-AF5D-32653244E022"

FontSize = 8

Alignment = 3

BorderStyle = 0

Margin = 0

Name = "Text1"


*** METHODS ***
PROCEDURE When

Return This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC

PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif

Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: pgrighe.Grid.ColQtaEvadibile) ***
*** PROPERTIES ***
Comment = "77B90C13-5725-46A3-9FEF-A0029AA5B68C"

FontSize = 8

BorderStyle = 0

Enabled = .F.

Margin = 0

Name = "Text1"


*** METHODS ***
PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif

Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: pgrighe.Grid.ColPrezzoUnitarioV) ***
*** PROPERTIES ***
Comment = "57890A3B-7FA7-4ED5-86B7-ECB39631AA75"

FontSize = 8

BorderStyle = 0

Margin = 0

Name = "Text1"


*** METHODS ***
PROCEDURE KeyPress

LParameters nKeyCode, nShiftAltCtrl



If nKeyCode = -2 																&& F3 - Fast Search

	This.ContextMenuProc(CMM_PROCESS_CHOICE, MB_EDIT_SRCHSPEC0)	

	NoDefault

	Return .T.

EndIf



If (nKeyCode = 83 Or nKeyCode = 115) And nShiftAltCtrl = 0 	&& s - Scorporo

	This.ContextMenuProc(CMM_PROCESS_CHOICE, MB_EDIT_SRCHSPEC1)

	NoDefault

	Return .T.

EndIf



Return DoDefault(nKeyCode, nShiftAltCtrl)



ENDPROC

PROCEDURE contextmenuproc

Lparameters nCBMId, xPar1, lFromCode



** Questo codice viene richiamato la prima volta dal menu (con lFromCode == .F.); la chiamata da menu

** deve essere rigirata nel metodo centralizzato Grid_ContextMenuProc,  che poi provvede a richiamare

** questo metodo, stavolta con lFromCode == .T. in modo da evitare la ricorsione



If !lFromCode

	Return This.Parent.Parent.Parent.Grid_ContextMenuProc(This, .F., nCBMId, xPar1)

Else

	Return DoDefault(nCBMId, xPar1)

EndIf



ENDPROC

PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif

Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC

PROCEDURE onvaluepick

LParameters nSearchFormType, xValue4Value, oSelectedRec, lFromCode



** Questo codice viene richiamato la prima volta dal menu (con lFromCode == .F.); la chiamata da menu

** deve essere rigirata nel metodo centralizzato Grid_OnValuePick, che poi provvede a richiamare

** questo metodo, stavolta con lFromCode == .T. in modo da evitare la ricorsione



If !lFromCode

	Return This.Parent.Parent.Parent.Grid_OnValuePick(This, .F., nSearchFormType, xValue4Value, oSelectedRec)

Else

	Return DoDefault(nSearchFormType, xValue4Value, oSelectedRec)

EndIf



ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: pgrighe.Grid.ColScontoRiga) ***
*** PROPERTIES ***
Comment = "D2119D01-A0D0-49F8-A0E8-0A2047D09E65"

FontName = "Segoe UI"

FontSize = 8

BorderStyle = 0

Margin = 0

Name = "Text1"


*** METHODS ***
PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif

Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: pgrighe.Grid.ColPrezzoTotaleV) ***
*** PROPERTIES ***
Comment = "EAD021B3-BE54-4AE2-814C-CE6BC37AF99A"

FontSize = 8

BorderStyle = 0

Enabled = .F.

Margin = 0

ReadOnly = .F.

Name = "Text1"


*** METHODS ***
PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif

Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: pgrighe.Grid.ColProvvigioneRiga_1) ***
*** PROPERTIES ***
Comment = "2ACF8D89-6620-4890-9CA9-D3F1ECC044CC"

FontSize = 8

BorderStyle = 0

Margin = 0

Name = "Text1"


*** METHODS ***
PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif

Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: pgrighe.Grid.ColDataConsegna) ***
*** PROPERTIES ***
Comment = "B2C2AE33-6214-4AA4-B546-209F1F158849"

FontSize = 8

BorderStyle = 0

Margin = 0

Name = "Text1"


*** METHODS ***
PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif

Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: pgrighe.Grid.ColProvvigioneRiga_2) ***
*** PROPERTIES ***
Comment = "8F96F147-83C3-4934-9533-0025007433BD"

FontSize = 8

BorderStyle = 0

Margin = 0

Name = "Text1"


*** METHODS ***
PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif

Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: pgrighe.Grid.ColCd_CAFormula) ***
*** PROPERTIES ***
Seconds = 2

BorderStyle = 0

Margin = 0

SelectOnEntry = .F.

TabIndex = 1

Name = "Text1"


*** METHODS ***
PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif

Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: pgrighe.Grid.ColCAPartenza) ***
*** PROPERTIES ***
Comment = "6117C828-84F1-4A67-B95E-CF4BD99EA00D"

Seconds = 2

BorderStyle = 0

Margin = 0

SelectOnEntry = .F.

TabIndex = 1

Name = "Text1"


*** METHODS ***
PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf



Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: pgrighe.Grid.ColCADurata) ***
*** PROPERTIES ***
Comment = "9E2D8B45-FBF6-4CE2-8381-1D78CF0CF20A"

Seconds = 2

BorderStyle = 0

Margin = 0

SelectOnEntry = .F.

TabIndex = 1

rangehighvalue = 240

rangelowvalue = 0

Name = "Text1"


*** METHODS ***
PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif

Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: pgrighe.Grid.ColRR_DataInizio) ***
*** PROPERTIES ***
Comment = "50C16DFA-B5F1-44EC-8784-C4B9BC4EC172"

FontSize = 8

BorderStyle = 0

Left = 58

Margin = 0

Top = 53

Name = "Text1"


*** METHODS ***
PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC

PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif



Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC

PROCEDURE tooltiptext_access

Return Iif(This.When(), DoDefault(), 'Campo non abilitato')

ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: pgrighe.Grid.ColRR_DataFine) ***
*** PROPERTIES ***
Comment = "E9911B47-200B-486F-BE34-58A544762005"

FontName = "Segoe UI"

FontSize = 8

BorderStyle = 0

Left = 50

Margin = 0

Top = 57

Name = "Text1"


*** METHODS ***
PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC

PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif



Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC

PROCEDURE tooltiptext_access

Return Iif(This.When(), DoDefault(), 'Campo non abilitato')

ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: pgrighe.Grid.ColRR_Cd_CGConto) ***
*** PROPERTIES ***
FontSize = 8

BorderStyle = 0

Left = 38

Margin = 0

Top = 65

Name = "Text1"


*** METHODS ***
PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC

PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif



Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC

PROCEDURE tooltiptext_access

Return Iif(This.When(), DoDefault(), 'Campo non abilitato')

ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: pgrighe.Grid.ColTipoPC) ***
*** PROPERTIES ***
Comment = "62F80E07-9AD8-4526-9DF1-81E1EAA35AE4"

Seconds = 2

Alignment = 2

BorderStyle = 0

ControlSource = "DoRig.TipoPC"

Format = "!"

Margin = 0

SelectOnEntry = .F.

TabIndex = 1

Name = "Text1"


*** METHODS ***
PROCEDURE onvaluechange

Lparameters xOldValue



** Ripristino condizione 2/2017 (SAS 3971)

** Richiamando l'OVC globale viene eseguito anche il post_formulae() che rimuove aliquota/conto in presenza di tipo = C e prezzototale = 0

** costringendo l'utente ad indicare prima la qta e poi ritornare sul tipoPC



** Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)



Return DoDefault(xOldValue)









ENDPROC

PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif



Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC

PROCEDURE contextmenuproc

Lparameters nCBMId, xPar1, lFromCode



** Questo codice viene richiamato la prima volta dal menu (con lFromCode == .F.); la chiamata da menu

** deve essere rigirata nel metodo centralizzato Grid_ContextMenuProc,  che poi provvede a richiamare

** questo metodo, stavolta con lFromCode == .T. in modo da evitare la ricorsione

If !lFromCode

	Return This.Parent.Parent.Parent.Grid_ContextMenuProc(This, .F., nCBMId, xPar1)

Else

	Return DoDefault(nCBMId, xPar1)

EndIf

ENDPROC

PROCEDURE KeyPress

LParameters nKeyCode, nShiftAltCtrl



** CTRL + F6 - Converti in padre/componenti

If nKeyCode = 99 And nShiftAltCtrl = 2 							

	This.ContextMenuProc(CMM_PROCESS_CHOICE, MB_EDIT_SRCHSPEC2, .F.)	

	NoDefault

	Return .T.

EndIf



** CTRL + F7 - Ricalcolo prezzo padre

If nKeyCode = 100 And nShiftAltCtrl = 2 							

	This.ContextMenuProc(CMM_PROCESS_CHOICE, MB_EDIT_SRCHSPEC3, .F.)	

	NoDefault

	Return .T.

EndIf



** CTRL + F8 - Ricalcolo prezzo tutti i padri

If nKeyCode = 101 And nShiftAltCtrl = 2 							

	This.ContextMenuProc(CMM_PROCESS_CHOICE, MB_EDIT_SRCHSPEC4, .F.)	

	NoDefault

	Return .T.

EndIf



Return DoDefault(nKeyCode, nShiftAltCtrl)

ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: pgrighe.Grid.ColCd_ReverseCharge) ***
*** PROPERTIES ***
FontSize = 9

Seconds = 2

BorderStyle = 0

ControlSource = "DORig.Cd_ReverseCharge"

Margin = 0

SelectOnEntry = .F.

TabIndex = 1

fkselect = SELECT * FROM ReverseCharge WHERE Cd_ReverseCharge = <TEXT> And TipoFattura > 1

Name = "Text1"


*** METHODS ***
PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: pgpiede.CntFattura.Grid.ColImportoV) ***
*** PROPERTIES ***
Comment = "69B51C50-CAC0-4F19-8084-6E613DB5F238"

FontSize = 8

BorderStyle = 0

Margin = 0

Name = "Text1"


*** METHODS ***
PROCEDURE When

Return DoDefault() And ((DORigSpesa.TipoRigaSpesa != 'T' Or DORigSpesa.Perc = 0) Or Thisform.Mode = FEDIMODE_SHOW)



ENDPROC

PROCEDURE isvalid

LPARAMETERS lIsChanged, xOldValue



IF !DODEFAULT(lIsChanged, xOldValue)

	RETURN .F.

ENDIF

IF lIsChanged

	RETURN THIS.PARENT.PARENT.PARENT.PARENT.Grid_IsValid(THIS, .F., xOldValue)

ELSE

	RETURN .T.

ENDIF

ENDPROC

PROCEDURE onvaluechange

LPARAMETERS xOldValue



This.Parent.Parent.Parent.Parent.ImportoVChange(xOldValue, This.Value)

This.Parent.Parent.ColImportoEvadibileV.Refresh()

This.Parent.Parent.ColImportoEvasoV.Refresh()



Replace ImportoE With Round(ImportoV / Dotes.Cambio, 2)



This.parent.parent.parent.parent.Setdorigspesa_defaults_DI('FOR')

This.parent.parent.parent.parent.Setdorigspesa_defaults_IVA()



ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: pgpiede.CntFattura.Grid.ColImportoEvadibileV) ***
*** PROPERTIES ***
Comment = "4DB5C44F-B0D5-4FE7-840C-A4D6E4D13915"

FontSize = 8

Seconds = 2

BorderStyle = 0

ControlSource = "DoRigSpesa.ImportoEvadibileV"

Margin = 0

SelectOnEntry = .F.

TabIndex = 1

Name = "Text1"


*** METHODS ***
PROCEDURE When

Return DoDefault() And ((DORigSpesa.TipoRigaSpesa != 'T' Or DORigSpesa.Perc = 0) Or Thisform.Mode = FEDIMODE_SHOW)

ENDPROC

PROCEDURE isvalid

LPARAMETERS lIsChanged, xOldValue



IF Empty(DODEFAULT(lIsChanged, xOldValue))

	xmessagebox(Thisform.TB_(,'996FC1F3-0946-4A0F-8D8F-794750962381', "L'importo evadibile non può essere superiore all'importo della spesa"))

	RETURN .F.

EndIf



RETURN This.Parent.Parent.Parent.Parent.Grid_isValid(THIS, .F., xOldValue)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: pgpiede.CntFattura.Grid.ColImportoEvasoV) ***
*** PROPERTIES ***
Comment = "2F605EF4-24C8-416D-92A8-66A7C70496BD"

FontSize = 8

Seconds = 2

BorderStyle = 0

ControlSource = "DoRigSpesa.ImportoEvasoV"

Margin = 0

SelectOnEntry = .F.

TabIndex = 1

Name = "Text1"


*** METHODS ***
PROCEDURE When

Return DoDefault() And !IsEmpty(DoRigSpesa.Id_DoRigSpesa_Evade)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: pgpiede.CntFattura.Grid.ColCd_CAformula) ***
*** PROPERTIES ***
FontSize = 8

Seconds = 2

BorderStyle = 0

Margin = 0

SelectOnEntry = .F.

TabIndex = 1

Name = "Text1"


*** METHODS ***
PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif



If lIsChanged

	Return This.Parent.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue)

Else

	Return .T.

Endif



ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: pgpiede.CntFattura.Grid.ColCd_SottoCommessa) ***
*** PROPERTIES ***
FontSize = 8

Seconds = 2

BorderStyle = 0

Margin = 0

SelectOnEntry = .F.

TabIndex = 1

fkselect = SELECT * FROM DOSottoCommessa WHERE Cd_DOSottoCommessa = <TEXT>

fktabledesc = Sottocommesse

Name = "Text1"


*** METHODS ***
PROCEDURE When

** Se il campo Sottocommessa della testa è valorizzato, non posso modificare la sottocommessa nelle righe e quindi

** imposto il campo ReadOnly.

**

** Attenzione!! Non si può far ritornare .F. da questo metodo altrimenti non viene valorizzata la property .ValueOnGotFocus 

** e se si esegue cmdAnnulla con il fuoco su questo campo (n.b. il fuoco viene dato anche se si ritorna .F. sul WHEN perche il controllo è su una colonna)

** viene sostituita la property .Value con .ValueOnGotFocus, cioè .F.



This.Parent.ReadOnly = !IsEmpty(DoTes.Cd_DOSottoCommessa) Or Thisform.Mode = FEDIMODE_SHOW



Return DoDefault()



ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: pgpiede.CntFattura.Grid.ColPerc) ***
*** PROPERTIES ***
Seconds = 2

BorderStyle = 0

Margin = 0

SelectOnEntry = .F.

TabIndex = 1

Name = "Text1"


*** METHODS ***
PROCEDURE When

Return DoDefault() And ((DORigSpesa.TipoRigaSpesa  = 'T' And (DORigSpesa.ImportoV = 0 Or DORigSpesa.Perc != 0) And DoTes.ImportiIvati = .F.) Or Thisform.Mode = FEDIMODE_SHOW)

ENDPROC

PROCEDURE tooltiptext_access

Return Alltrim(DoRigSpesa.Descrizione) + ' : ' + Transform(This.Parent.Parent.Parent.Parent.CalcolaSpesePerc(), '###,###,###.##')

ENDPROC

PROCEDURE onvaluechange

LPARAMETERS xOldValue



This.parent.parent.parent.parent.Setdorigspesa_defaults_DI('FOR')

This.parent.parent.parent.parent.Setdorigspesa_Defaults_IVA()

ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: pgpiede.CntFattura.Grid.ColCd_ReverseCharge) ***
*** PROPERTIES ***
FontSize = 9

Seconds = 2

BorderStyle = 0

ControlSource = "DORigSpesa.Cd_ReverseCharge"

Margin = 0

SelectOnEntry = .F.

TabIndex = 1

fkselect = SELECT * FROM ReverseCharge WHERE Cd_ReverseCharge = <TEXT> And TipoFattura > 1

Name = "Text1"


*** METHODS ***
PROCEDURE onvaluechange

LPARAMETERS xOldValue



DoDefault(xOldValue)



This.parent.parent.parent.parent.Setdorigspesa_defaults_DI('FOR')



AddProperty(This.parent.parent.parent.parent, 'RC_OnValueChange', .T.)

This.parent.parent.parent.parent.Setdorigspesa_Defaults_IVA()



ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Parent.Grid_When(This)



ENDPROC


*======================================================================

*** CLASS / OBJECT: detail (BaseClass: form, Parent: ) ***
*** PROPERTIES ***
Top = 0

Left = 1

Height = 535

Width = 532

DoCreate = .T.

Comment = "8D4E7DD8-A57E-47E9-AFAB-B151A115C433"

MousePointer = 0

wrkalias = DORIG

Name = "detail"

StatusBar.BorderLine.Name = "BorderLine"

StatusBar.TimerDate.Name = "TimerDate"

StatusBar.TimerRepos.Name = "TimerRepos"

StatusBar.Comment = "D1E1D36D-E9B7-4CB1-BAC9-EF70288C14C9"

StatusBar.Top = 515

StatusBar.Width = 532

StatusBar.Height = 20

StatusBar.TabIndex = 3

StatusBar.ZOrderSet = 0

StatusBar.Name = "StatusBar"

timer4ExecAsync.Comment = "3DCD7634-C7E1-4F3C-AAF6-DA45C5779F1C"

timer4ExecAsync.Name = "timer4ExecAsync"

title_bar.BtnLabel.Name = "BtnLabel"

title_bar.lblLabel.Name = "lblLabel"

title_bar.Comment = "21D6C11E-178D-4DA6-89F4-C0C14AA48810"

title_bar.Top = 26

title_bar.Width = 532

title_bar.TabIndex = 2

title_bar.ZOrderSet = 2

title_bar.caption = ('Titolo')

title_bar.Name = "title_bar"

SCMenu.Comment = "2E4EAD10-33A3-4511-8A3B-432355A5C684"

SCMenu.Name = "SCMenu"

tbenabler.Comment = "29477ECF-C354-4FA0-A3AA-1A71BFBF1050"

tbenabler.Name = "tbenabler"

PF.ErasePage = .T.

PF.PageCount = 5

PF.Pgbase1.Comment = "7D0A097D-0A9C-4BA5-9FA0-D3DBA53E5007"

PF.Pgbase1.Caption = "Dettaglio Riga"

PF.Pgbase1.PageOrder = 1

PF.Pgbase1.Name = "pgGenerale"

PF.Pgbase2.Comment = "B18EF385-D505-444D-99F6-EB2FCDBBB220"

PF.Pgbase2.Caption = "Allegati"

PF.Pgbase2.PageOrder = 5

PF.Pgbase2.Name = "pgAllegati"

PF.Pgbase3.Comment = "B3F77C4A-8CE7-44E2-9AE2-CE7C2A2C6CFD"

PF.Pgbase3.Caption = "Analitica"

PF.Pgbase3.PageOrder = 4

PF.Pgbase3.Name = "pgCOAN"

PF.Pgbase4.Caption = "Fattura Elettronica"

PF.Pgbase4.PageOrder = 2

PF.Pgbase4.Name = "pgFEPA"

PF.Pgbase5.Caption = "Fattura Elettronica"

PF.Pgbase5.PageOrder = 3

PF.Pgbase5.Name = "pgSemplificata"

PF.Comment = "853518F4-C00F-48B8-9E17-A4C56712D5ED"

PF.ActivePage = 1

PF.Top = 28

PF.Width = 534

PF.Height = 486

PF.TabIndex = 1

PF.ZOrderSet = 5

PF.Name = "PF"


*** METHODS ***
PROCEDURE cmdrowdel

Local oCtrl



If This.Mode = FEDIMODE_SHOW

	Return .F.

EndIf



This.PF.pgGenerale.txtMatricole.Grid.SaveRecordSource()

This.oCaller.oMatricole.CursorToXml(This.Mode == FEDIMODE_SHOW)



** Riporto i dati nel campo XML

This.Fepa_Set()



** Siccome almeno un controllo ha il fuoco nel momento del comando accade che a seguito del Refresh()

** il controllo ha un nuovo .Value mentre il .ValueOnGotFocus è quello precedente e vengono scatenati

** così degli errati OnValueChange();  per questa ragione viene invocato il .GotFocus() che si occupa

** di aggiornare .ValueOnGotFocus al valore corretto corrente di .Value



If Type('ThisForm.ActiveControl') == 'O'

	oCtrl = ThisForm.ActiveControl

	This.Parameters.ParentForm.CmdRowDel(.T.)

	This.PF.pgGenerale.Refresh()

	This.OnRefresh()

	If PemStatus(oCtrl, 'GotFocus', 5)

		oCtrl.GotFocus()

	EndIf 

	This.StepEnabler()

EndIf



This.oCaller.oMatricole.XmlToCursor()

This.PF.pgGenerale.txtMatricole.Grid.RestoreRecordSource()			



Go Top In DoRigPackList



This.PF.pgGenerale.txtMatricole	.Grid.Refresh()

This.PF.pgGenerale.txtPackingList.Grid.Refresh()



** Leggo i dati del record successivo

This.Fepa_Get()

ENDPROC

PROCEDURE cmdrowins

Local oCtrl



If This.Mode = FEDIMODE_SHOW Or !This.Validate()

	Return .F.

EndIf



This.PF.pgGenerale.txtMatricole.Grid.SaveRecordSource()

This.oCaller.oMatricole.CursorToXml(This.Mode == FEDIMODE_SHOW)



** Riporto i dati nel campo XML

This.Fepa_Set()



** Siccome almeno un controllo ha il fuoco nel momento del comando accade che a seguito del Refresh()

** il controllo ha un nuovo .Value mentre il .ValueOnGotFocus è quello precedente e vengono scatenati

** così degli errati OnValueChange();  per questa ragione viene invocato il .GotFocus() che si occupa

** di aggiornare .ValueOnGotFocus al valore corretto corrente di .Value



If Type('ThisForm.ActiveControl') == 'O'

	oCtrl = ThisForm.ActiveControl

	This.Parameters.ParentForm.CmdRowCopy(.T.)

	This.Parameters.ParentForm.CmdRowAdd(.T.)

	This.Parameters.ParentForm.CmdRowPaste(.T.)

	This.PF.pgGenerale.Refresh()

	This.OnRefresh() 

	If PemStatus(oCtrl, 'GotFocus', 5)

		oCtrl.GotFocus()

	EndIf 

	This.StepEnabler()

EndIf



This.oCaller.oMatricole.XmlToCursor()

This.PF.pgGenerale.txtMatricole.Grid.RestoreRecordSource()



Go Top In DoRigPackList



This.PF.pgGenerale.txtMatricole	.Grid.Refresh()

This.PF.pgGenerale.txtPackingList.Grid.Refresh()



** Leggo i dati del record successivo

This.Fepa_Get()



ThisForm.PF.ActivePage = 1



Select DoRig



ENDPROC

PROCEDURE cmdrowadd

Local oCtrl



If This.Mode = FEDIMODE_SHOW Or !This.Validate()

	Return .F.

EndIf



This.PF.pgGenerale.txtMatricole.Grid.SaveRecordSource()

This.oCaller.oMatricole.CursorToXml(This.Mode == FEDIMODE_SHOW)



** Riporto i dati nel campo XML

This.Fepa_Set()



** Siccome almeno un controllo ha il fuoco nel momento del comando accade che a seguito del Refresh()

** il controllo ha un nuovo .Value mentre il .ValueOnGotFocus è quello precedente e vengono scatenati

** così degli errati OnValueChange();  per questa ragione viene invocato il .GotFocus() che si occupa

** di aggiornare .ValueOnGotFocus al valore corretto corrente di .Value



If Type('ThisForm.ActiveControl') == 'O'

	oCtrl = ThisForm.ActiveControl

	This.Parameters.ParentForm.CmdRowAdd(.T.)

	This.PF.pgGenerale.Refresh()

	This.OnRefresh() 

	If PemStatus(oCtrl, 'GotFocus', 5)

		oCtrl.GotFocus()

	EndIf 

	This.StepEnabler()

EndIf



This.oCaller.oMatricole.XmlToCursor()

This.PF.pgGenerale.txtMatricole.Grid.RestoreRecordSource()			



Go Top In DoRigPackList



This.PF.pgGenerale.txtMatricole	.Grid.Refresh()

This.PF.pgGenerale.txtPackingList.Grid.Refresh()



** Leggo i dati del record successivo

This.Fepa_Get()



ThisForm.PF.ActivePage = 1



Select DoRig



ENDPROC

PROCEDURE cmdmatricolaadd

LPARAMETERS oControl

IF VARTYPE(oControl) != 'O'

	oControl = THISFORM.ActiveControl

ENDIF	

IF VARTYPE(oControl) = 'O' AND oControl.BaseClass = 'Grid'

	oControl.RowAppend()	

ENDIF	



ENDPROC

PROCEDURE cmdmatricoladel

LOCAL oControl



oControl = THISFORM.ActiveControl

IF VARTYPE(oControl) = 'O' AND oControl.BaseClass = 'Grid'

	IF !EOF(oControl.RecordSource) AND !BOF(oControl.RecordSource)

		oControl.RowDelete()	

	ENDIF

ENDIF	





ENDPROC

PROCEDURE mode_access

RETURN THISFORM.Parameters.ParentForm.Mode

ENDPROC

PROCEDURE cmdeditpacklist

WITH THISFORM.Parameters.ParentForm

	IF .DE.DORig.ReccountND() > 0

		SELECT DORIGPackList

		IF ThisForm.Mode = FEDIMODE_SHOW AND TAGNO('Id_DoRig') = 0

			.DE.DoRigPackList.RunCmd('SET FILTER TO Id_DORig = xDefault(DORig.Id_DoRig, RECNO("DORig"))')

		ENDIF

		LOCAL oPackListForm

		oPackListForm = RunDetail('Fedi_Doc', THISFORM)

		oPackListForm.Caption = 'Packing list'

		IF ThisForm.Mode = FEDIMODE_SHOW

			oPackListForm.SetAll('Readonly', .T.)

		ENDIF

		oPackListForm.SHOW(1)

		oPackListForm = NULL

	ENDIF

ENDWITH



ENDPROC

PROCEDURE caricapackinglist

Lparameters nId_DoRig

Local nOldWA

nOldWA = Select(0)

Local cFilter

Select DorigPackList

cFilter = Set("Filter")

Set Filter To

Seek nId_DoRig Order Tag Id_DoRig In DorigPackList

Set Filter To &cFilter



If !Found('DoRigPackList') && Carico per la prima volta le matricole

	Local oRec

	Local cStmt



	TEXT TO cStmt NOSHOW TEXTMERGE

		SELECT *	FROM DoRigPackList WHERE id_DoRig = <<nId_DoRig>> ORDER BY Riga

	ENDTEXT



	xSqlExec(cStmt, '__PackList')



	Select __PackList



	Scan

		Scatter Name oRec Memo



		Select DorigPackList

		Append Blank

		Gather Name oRec Memo

		Tableupdate(0, .T., 'DoRigPackList')



		Select __PackList

	Endscan



	Use In __PackList



	Go Top In DorigPackList

Endif

Select (nOldWA)



ENDPROC

PROCEDURE checkpackinglist

If This.oCaller.Mode == FEDIMODE_SHOW

	Return .F.

EndIf



********************************************************************************



Local lRet

lRet = .T.

If IsActivable() And This.PF.pgGenerale.txtPackingList.Visible

	Local nSum

	Select DoRigPackList

	nRec = Recno()

	Calculate Sum(Qta) To nSum

	If (nSum != Dorig.Qta)

		lRet = QuestionBox(RL_BASE, "La quantità indicata non corrisponde alla somma delle quantità associate al packing list.", "proseguire")

	Endif

	Locate Record (nRec)

Endif

Return lRet



ENDPROC

PROCEDURE queryexit

Return (This.Mode == FEDIMODE_SHOW Or Thisform.Validate())



ENDPROC

PROCEDURE checkmatricole

If This.oCaller.Mode == FEDIMODE_SHOW

	Return .F.

EndIf



** ----- LICADAPTER

If !oApp.LicInfo.DO_LottiMatr

	Return .T.

EndIf



** Verifico che SE le matricole ci sono e le impostazioni del BLS lo richiedono

** allora QtaUM1 e #Matricole siano coerenti; inoltre verifico che le matricole

** SE ci sono siano univoche;  l'obbligatorietà delle matricole  per l'articolo

** viene invece testata nel trigger di MGMov in modo sicuro



** Tale controllo è fatto anche dal QuerySave della Fedi



Local lRet



*This.PF.pgGenerale.TxtCd_AR.Field.SetFocus()

This.PF.pgGenerale.txtMatricole.Grid.SaveRecordSource()

This.oCaller.oMatricole.CursorToXml(This.oCaller.Mode == FEDIMODE_SHOW)



lRet = This.oCaller.oMatricole.CheckMatricoleXml(.T.)



This.oCaller.oMatricole.XmlToCursor()

This.PF.pgGenerale.txtMatricole.Grid.RestoreRecordSource()

*This.PF.pgGenerale.txtMatricole.Grid.SetFocus()



Return lRet



ENDPROC

PROCEDURE validate

Local oCtrl, lRet, xRet



oCtrl = Thisform.GetActiveControl(.T.)

If IsNull(oCtrl)

	lRet = .T.

Else

	If Pemstatus(oCtrl, 'Valid', 5)

		xRet = oCtrl.Valid(.T.)

		If Vartype(xRet) = 'L' And xRet = .F.

			Wait Window (xDefault(oCtrl.ErrorMessage(), 'Dato non valido.'))

		EndIf

		lRet = !IsEmpty(xRet)

	Else

		lRet = .T.

	EndIf

EndIf



lRet =	lRet And ;

			This.CheckMatricole() And ;

			This.CheckPackingList() And ;

			This.Fepa_Validate()



If !lRet And PemStatus(oCtrl, 'SetFocus', 5)

	oCtrl.SetFocus()

EndIf



Return lRet





ENDPROC

PROCEDURE fepa_setcontrolsource

Local cAlias, cAlias_1, cAlias_2



If !Thisform.FepaEnabled

	Return .T.

EndIf



cAlias 	= This.oCaller.oFtexml.Alias_RDoc

cAlias_1 = This.oCaller.oFtexml.Alias_RDoc_1

cAlias_2 = This.oCaller.oFtexml.Alias_RDoc_2



If Thisform.FepaSchema = 1



	With ThisForm.PF.pgFEPA



	.PFX.pgDati.TxtRiferimentoAmm.Field.ControlSource 			= cAlias + '.DG_RiferimentoAmm'

	.PFX.pgDati.txtDataInizio.Field.ControlSource 				= cAlias + '.DG_DataInizioPeriodo'

	.PFX.pgDati.TxtDataFine.Field.ControlSource 					= cAlias + '.DG_DataFinePeriodo'



	.PFX.pgAltri.Grid_RDOC1.RecordSource							= cAlias_1

	.PFX.pgAltri.Grid_RDOC1.ColRiga.ControlSource				= cAlias_1 + '.Riga'

	.PFX.pgAltri.Grid_RDOC1.ColTipoDato.ControlSource			= cAlias_1 + '.TipoDato'

	.PFX.pgAltri.Grid_RDOC1.ColRifTesto.ControlSource			= cAlias_1 + '.RiferimentoTesto'

	.PFX.pgAltri.Grid_RDOC1.ColRifNumero.ControlSource			= cAlias_1 + '.RiferimentoNumero'

	.PFX.pgAltri.Grid_RDOC1.ColRifData.ControlSource			= cAlias_1 + '.RiferimentoData'



	.PFX.pgCodice.Grid_RDOC2.RecordSource							= cAlias_2

	.PFX.pgCodice.Grid_RDOC2.ColRiga.ControlSource				= cAlias_2 + '.Riga'

	.PFX.pgCodice.Grid_RDOC2.ColCodiceTipo.ControlSource		= cAlias_2 + '.CodiceTipo'

	.PFX.pgCodice.Grid_RDOC2.ColCodiceValore.ControlSource	= cAlias_2 + '.CodiceValore'



	.PFX.pgDati.txtQta.Field.Inputmask 					= ThisForm.PF.pgGenerale.txtQta.Field.Inputmask

	.PFX.pgDati.TxtPrezzoUnitario.Field.Inputmask 	= ThisForm.PF.pgGenerale.txtPrezzoUnitarioV.Field.Inputmask

	.PFX.pgDati.TxtScontoValore.Field.Inputmask 		= ThisForm.PF.pgGenerale.txtPrezzoTotaleV.Field.Inputmask

	.PFX.pgDati.TxtPrezzoTotale.Field.Inputmask 		= ThisForm.PF.pgGenerale.txtPrezzoTotaleV.Field.Inputmask

	.PFX.PgDati.TxtAliquota.Field.Inputmask 			= '###.##'



	** Rilevo i dati dei riferimenti



	With .PFR.PGO.CntData



	.TxtIdDocumento.Field.ControlSource		= cAlias + '.OR_IdDocumento'

	.TxtData.Field.ControlSource				= cAlias + '.OR_Data'

	.TxtNumItem.Field.ControlSource			= cAlias + '.OR_NumItem'

	.TxtCommessa.Field.ControlSource			= cAlias + '.OR_Commessa'

	.TxtCup.Field.ControlSource				= cAlias + '.OR_CodiceCup'

	.TxtCig.Field.ControlSource				= cAlias + '.OR_CodiceCig'



	EndWith



	With .PFR.PGC.CntData



	.TxtIdDocumento.Field.ControlSource		= cAlias + '.CN_IdDocumento'

	.TxtData.Field.ControlSource				= cAlias + '.CN_Data'

	.TxtNumItem.Field.ControlSource			= cAlias + '.CN_NumItem'

	.TxtCommessa.Field.ControlSource			= cAlias + '.CN_Commessa'

	.TxtCup.Field.ControlSource				= cAlias + '.CN_CodiceCup'

	.TxtCig.Field.ControlSource				= cAlias + '.CN_CodiceCig'



	EndWith



	With .PFR.PGV.CntData



	.TxtIdDocumento.Field.ControlSource		= cAlias + '.CV_IdDocumento'

	.TxtData.Field.ControlSource				= cAlias + '.CV_Data'

	.TxtNumItem.Field.ControlSource			= cAlias + '.CV_NumItem'

	.TxtCommessa.Field.ControlSource			= cAlias + '.CV_Commessa'

	.TxtCup.Field.ControlSource				= cAlias + '.CV_CodiceCup'

	.TxtCig.Field.ControlSource				= cAlias + '.CV_CodiceCig'



	EndWith



	With .PFR.PGR.CntData



	.TxtIdDocumento.Field.ControlSource		= cAlias + '.RC_IdDocumento'

	.TxtData.Field.ControlSource				= cAlias + '.RC_Data'

	.TxtNumItem.Field.ControlSource			= cAlias + '.RC_NumItem'

	.TxtCommessa.Field.ControlSource			= cAlias + '.RC_Commessa'

	.TxtCup.Field.ControlSource				= cAlias + '.RC_CodiceCup'

	.TxtCig.Field.ControlSource				= cAlias + '.RC_CodiceCig'



	EndWith



	With .PFR.PGL.CntData



	.TxtIdDocumento.Field.ControlSource		= cAlias + '.FC_IdDocumento'

	.TxtData.Field.ControlSource				= cAlias + '.FC_Data'

	.TxtNumItem.Field.ControlSource			= cAlias + '.FC_NumItem'

	.TxtCommessa.Field.ControlSource			= cAlias + '.FC_Commessa'

	.TxtCup.Field.ControlSource				= cAlias + '.FC_CodiceCup'

	.TxtCig.Field.ControlSource				= cAlias + '.FC_CodiceCig'



	EndWith



	With .PFR.PGD.CntData



	.txtIdDocumento.Field.ControlSource 	= cAlias + '.DG_NumeroDDT'

	.txtData.Field.ControlSource 				= cAlias + '.DG_DataDDT'



	EndWith



	EndWith



	This.Fepa_Get_OA_Data()



Else



	With ThisForm.PF.pgSemplificata



	**		.PFX.pgDati.TxtImporto.Field.ControlSource 		= cAlias + '.DG_Importo'

	**		.PFX.pgDati.txtImposta.Field.ControlSource 		= cAlias + '.DG_Imposta'



	.PFX.pgDati.txtQta.Field.Inputmask 					= ThisForm.PF.pgGenerale.txtQta.Field.Inputmask

	.PFX.pgDati.TxtPrezzoUnitario.Field.Inputmask 	= ThisForm.PF.pgGenerale.txtPrezzoUnitarioV.Field.Inputmask

	.PFX.pgDati.TxtScontoValore.Field.Inputmask 		= ThisForm.PF.pgGenerale.txtPrezzoTotaleV.Field.Inputmask

	.PFX.pgDati.TxtPrezzoTotale.Field.Inputmask 		= ThisForm.PF.pgGenerale.txtPrezzoTotaleV.Field.Inputmask

	.PFX.PgDati.TxtAliquota.Field.Inputmask 			= '###.##'



	.PFX.pgDati.TxtImporto.Field.Inputmask				= ThisForm.PF.pgGenerale.txtPrezzoTotaleV.Field.Inputmask

	.PFX.pgDati.txtImposta.Field.Inputmask				= ThisForm.PF.pgGenerale.txtPrezzoTotaleV.Field.Inputmask



	EndWith



EndIf



This.Fepa_Get_DG_Data()

ENDPROC

PROCEDURE fepa_setuiconfig

ThisForm.PF.pgFEPA.Enabled 			= (Thisform.FepaSchema = 1)

ThisForm.PF.pgSemplificata.Enabled 	= (Thisform.FepaSchema = 2) && And IsActivable('ARCA_FSM10FAQ27')

			

** Al momento non metto campi in più per la semplificata (potrebbero essere imponibile ed imposta per gestire il caso di variazione sola iva)

** Per cui è inutile mostrare una pagina che non serve



With ThisForm.PF.pgFEPA



.PFX.pgAltri.Grid_RDOC1.AllowAddNew 	= (Thisform.Mode != FEDIMODE_SHOW)

.PFX.pgCodice.Grid_RDOC2.AllowAddNew 	= (Thisform.Mode != FEDIMODE_SHOW)



.PFX.pgAltri.btnAdd.Visible = (Thisform.Mode != FEDIMODE_SHOW)

.PFX.pgAltri.btnDel.Visible = (Thisform.Mode != FEDIMODE_SHOW)



.PFX.pgCodice.btnAdd.Visible = (Thisform.Mode != FEDIMODE_SHOW)

.PFX.pgCodice.btnDel.Visible = (Thisform.Mode != FEDIMODE_SHOW)



Iif(Thisform.Mode = FEDIMODE_SHOW, ObjDim(.PFX.pgAltri.Grid_RDOC1 , , , .PFX.pgAltri.btnAdd.Right + 1), .T.)

Iif(Thisform.Mode = FEDIMODE_SHOW, ObjDim(.PFX.pgCodice.Grid_RDOC2, , , .PFX.pgCodice.btnAdd.Right + 1), .T.)



ObjMov(.PFR.PGO.CntRead, .PFR.PGO.CntData.Left, .PFR.PGO.CntData.Top)

ObjMov(.PFR.PGD.CntRead, .PFR.PGD.CntData.Left, .PFR.PGD.CntData.Top)



.PFR.Tabs = .F.



EndWith





ENDPROC

PROCEDURE fepa_validate

Local cText, cAlias, oWA



** Non gestisco nulla nel caso il documento non sia FEPA.

If !Thisform.FepaEnabled

	Return .T.

EndIf



oWA		= SelectWA()

cText 	= ''



** Altri dati Gestionali

cAlias = This.oCaller.oFtexml.Alias_RDoc_1



Select (cAlias)

Locate For (!IsEmpty(&cAlias..RiferimentoTesto) Or !IsEmpty(&cAlias..RiferimentoNumero) Or !IsEmpty(&cAlias..RiferimentoData)) And IsEmpty(&cAlias..TipoDato)

If Found(cAlias)

	cText = cText + Thisform.TB_(,'A92F96F6-2959-42F9-B439-BB06E3322BAE', '- Tipo Dato mancante nella sezione <altri dati gestionali>.') + Chr(13)

EndIf

Go Top In (cAlias)



** Codici articolo

cAlias = This.oCaller.oFtexml.Alias_RDoc_2



Select (cAlias)

Locate For (IsEmpty(&cAlias..CodiceTipo) And !IsEmpty(&cAlias..CodiceValore)) Or (!IsEmpty(&cAlias..CodiceTipo) And IsEmpty(&cAlias..CodiceValore))

If Found(cAlias)

	cText = cText + Thisform.TB_(,'9837ABDE-EE8A-4671-BF90-C40FB843FBDD', '- Tipo codice o valore mancante nella sezione <codice articolo>.') + Chr(13)

EndIf

Go Top In (cAlias)



If !Empty(cText) 



	cText =	Thisform.TB_(,'222A6DFA-D6B5-47FC-A8DB-5AB8CC6F0E4B', "ATTENZIONE! Verificare le seguenti condizioni: ") + Chr(13) + Chr(13) + ;

				cText + Chr(13) + ;

				Thisform.TB_(,'325BBB30-09A5-487E-A448-3C28A1E475CF', "Continuo?")

	

	If xMessageBox(cText, MB_ICONQUESTION + MB_YESNO) = IDNO

		Return .F.

	EndIf

	

EndIf



ENDPROC

PROCEDURE fepa_enabled

** Al momento la gestione dei dati per riga si abilita soltanto per le fatture.

** Se si volesse abilitarla anche per l'ordine basta eliminare la condizione dopo l'AND. I dati inseriti nelle righe dell'ordine

** vengono regolarmente prelevati in DDT e/o fattura e di conseguenza come fossero inseriti in fattura.



Return (Vartype(This.oCaller.oFteXml) == 'O' And This.oCaller.Toolbar.Buttons('FTEXML').Enabled And This.oCaller.PF.pgGenerale.txtCd_DO.Field.FkRecord.TipoDocumento $ 'FAN')



ENDPROC

PROCEDURE fepa_get_oa_data

Lparameters nId_Dorig



Local cScript, nId_Dorig, oRec



nId_Dorig = Nvl(xDefault(nId_Dorig, Iif(DoRig.Id_Dorig < 0, DoRig.Id_Dorig_Evade, DoRig.Id_Dorig)), 0)



** ORDER/DDT DATA LOAD



Text To cScript Textmerge Noshow



Declare @RCTE Table (Id_DoRig_A Int, Id_DoRig Int, Id_DoRig_Evade Int, Id_Dotes Int, Riga Int, Cd_DOSottoCommessa Varchar(Max), TipoDocumento Char(1), Level Bit)



;With

	RCTE_R As

	(

		Select Id_DoRig_A = R.Id_DoRig,   R.Id_DoRig, R.Id_DoRig_Evade, R.Id_Dotes, R.Riga, R.Cd_DOSottoCommessa, R.TipoDocumento From DoRig R Where R.Id_Dorig = <<Int(nId_DoRig)>> Union All

		Select Id_DoRig_A = P.Id_DoRig_A, C.Id_DoRig, C.Id_DoRig_Evade, C.Id_Dotes, C.Riga, C.Cd_DOSottoCommessa, C.TipoDocumento From DoRig C Join RCTE_R P On C.Id_DORig = P.Id_DoRig_Evade

	)

Insert Into @RCTE Select *, 0 From RCTE_R

Update R Set Level = 1 From @RCTE R Join (Select Id_DoRig_A, TipoDocumento, Id_DoRig = Max(Id_DoRig) From @RCTE Where TipoDocumento In ('O', 'B') Group By Id_DoRig_A, TipoDocumento) X On R.Id_DoRig_A = X.Id_Dorig_A And R.Id_DoRig = X.Id_Dorig



Select

	  OT_Id_Dotes		= OT.Id_Dotes

	, OT_Id_Dorig		= RO.Id_Dorig

	, OT_IdDocumento	= IsNull(OT.NumeroDocRif, OT.NumeroDoc)

	, OT_Data			= IsNull(OT.DataDocRif, OT.DataDoc)

	, OT_NumItem		= RO.Riga

	, OT_Commessa		= IsNull(RO.Cd_DOSottoCommessa, OT.Cd_DOSottoCommessa)

	, OT_CodiceCUP 	= OT.FTE_XML.value('(/rows/row/@dg_codicecup)[1]', 'varchar(15)')

	, OT_CodiceCIG 	= OT.FTE_XML.value('(/rows/row/@dg_codicecig)[1]', 'varchar(15)')

	, BT_Id_Dotes		= BT.Id_Dotes

	, BT_Id_Dorig		= RB.Id_Dorig

	, BT_NumItem		= RB.Riga	

	, BT_IdDocumento	= IsNull(BT.NumeroDocRif, BT.NumeroDoc)

	, BT_Data			= IsNull(BT.DataDocRif, BT.DataDoc)

From Dorig			DR

Left Join @RCTE 	RO On DR.Id_DoRig = RO.Id_DoRig_A And RO.TipoDocumento = 'O' And RO.Level = 1

Left Join @RCTE	RB On DR.Id_DoRig = RB.Id_DoRig_A And RB.TipoDocumento = 'B' And RB.Level = 1

Left Join DOTes 	OT On RO.Id_DoTes = OT.Id_DoTes

Left Join DOTes 	BT On RB.Id_DoTes = BT.Id_DoTes

Where DR.Id_Dorig = <<Int(nId_DoRig)>>

	

EndText



oRec = xSQLExec2Obj(cScript, .T.)



With ThisForm.PF.pgFEPA.PFR.PGO.CntRead



.txtIdDocumento.Field.SetValue(	Evl(Alltrim(oRec.OT_IdDocumento), Null))

.txtData.Field.SetValue(			Evl(oRec.OT_Data, Null))

.txtCommessa.Field.SetValue(		Evl(oRec.OT_Commessa, Null))

.TxtCig.Field.SetValue(				Evl(oRec.OT_CodiceCIG, Null))

.TxtCup.Field.SetValue(				Evl(oRec.OT_CodiceCUP, Null))

.TxtNumItem.Field.SetValue(		Evl(oRec.OT_NumItem, Null))



AddProperty(.TxtNumItem, 'Id_Dotes', oRec.OT_Id_Dotes)

AddProperty(.TxtNumItem, 'Id_Dorig', oRec.OT_Id_Dorig)



** Show readonly dataset or not

.Parent.CntRead.Visible = !IsEmpty(oRec.OT_Id_Dorig)

.Parent.CntData.Visible =  IsEmpty(oRec.OT_Id_Dorig)



EndWith



With ThisForm.PF.pgFEPA.PFR.PGD.CntRead



.txtIdDocumento.Field.SetValue(	Evl(Alltrim(oRec.BT_IdDocumento), Null))

.txtData.Field.SetValue(			Evl(oRec.BT_Data, Null))

.TxtNumItem.Field.SetValue(		Evl(oRec.BT_NumItem, Null))



AddProperty(.TxtNumItem, 'Id_Dotes', oRec.BT_Id_Dotes)

AddProperty(.TxtNumItem, 'Id_Dorig', oRec.BT_Id_Dorig)



** Show readonly dataset or not

.Parent.CntRead.Visible = !IsEmpty(oRec.BT_Id_Dorig)

.Parent.CntData.Visible =  IsEmpty(oRec.BT_Id_Dorig)



EndWith





ENDPROC

PROCEDURE fepa_get_dg_data

Local oPage, oAli, xValue



oAli = xSQLExec2Obj(Textmerge('Select Cd_Aliquota, Aliquota, Cd_Natura From Aliquota Where Cd_Aliquota = <<FormatC4Spt(Dorig.Cd_Aliquota_R)>>'), .T.)



oPage = Iif(This.FepaSchema = 2, ThisForm.PF.pgSemplificata, ThisForm.PF.pgFEPA)



oPage.txtCd_AR.Field.SetValue(DoRig.Cd_Ar)

oPage.txtDescrizione.Field.SetValue(DoRig.Descrizione)



oPage.PFX.PgDati.txtCd_ARMisura.Field.SetValue(DoRig.Cd_ArMisura)

oPage.PFX.PgDati.txtQta.Field.SetValue(DoRig.Qta)

oPage.PFX.pgDati.TxtPrezzoUnitario.Field.SetValue(Dorig.PrezzoUnitarioV + Dorig.PrezzoAddizionaleV)

oPage.PFX.pgDati.TxtScontoValore.Field.SetValue((Dorig.PrezzoUnitarioV - Dorig.PrezzoUnitarioScontatoV) * Dorig.Qta)

oPage.PFX.PgDati.TxtPrezzoTotale.Field.SetValue(DoRig.PrezzoTotaleV)

oPage.PFX.pgDati.TxtAliquota.Field.SetValue(oAli.Aliquota)

oPage.PFX.PgDati.txtCd_Aliquota.Field.SetValue(oAli.Cd_Aliquota)



** Cerco la natura nella testa dei dati aggiuntivi e aliquota

This.oCaller.oFtexml.TDoc_XMLToCursor(Dotes.FTE_Xml)

xValue = NEvl(This.oCaller.oFtexml.TDoc.DG_Natura, xSqlExec2Var(Textmerge('Select dbo.afn_FE_GetNatura(<<FormatC4Spt(oAli.Cd_Aliquota)>>)')))

oPage.PFX.PgDati.txtNatura.Field.SetValue(xValue)

This.oCaller.oFtexml.TDOC_WA_Destroy()



** Solo Semplificata

If This.FepaSchema = 2

	

	If This.oCaller.PF.pgGenerale.txtCd_DO.Field.FKRecord.FTe_NotaIva



		oPage.PFX.pgDati.TxtImporto.Field.SetValue(Dorig.PrezzoTotaleV)

		oPage.PFX.pgDati.txtImposta.Field.SetValue(Dorig.PrezzoTotaleV)

	

	Else

	

		oPage.PFX.pgDati.TxtImporto.Field.SetValue(Iif(Dotes.ImportiIvati, Dorig.PrezzoTotaleV, Dorig.PrezzoTotaleE + Arrotonda(Dorig.PrezzoTotaleE * oAli.Aliquota / 100, 2)))

		oPage.PFX.pgDati.txtImposta.Field.SetValue(Iif(Dotes.ImportiIvati, Iif(IsEmpty(oAli.Aliquota), 0, Dorig.PrezzoTotaleV - Dorig.PrezzoTotaleE), Arrotonda(Dorig.PrezzoTotaleE * oAli.Aliquota / 100, 2)))



	EndIf

	

EndIf





ENDPROC

PROCEDURE fepa_set

Local cXml



If Thisform.FepaEnabled



	If Thisform.FepaSchema = 1

	

		This.PF.pgFEPA.PFX.pgAltri.Grid_RDOC1.SaveRecordSource()

		This.PF.pgFEPA.PFX.pgCodice.Grid_RDOC2.SaveRecordSource()



	EndIf

	

	If This.Mode != FEDIMODE_SHOW 



		cXml = This.oCaller.oFteXml.RDOC_CursorToXML()

		If !SafeCompare(DoRig.FTE_Xml, cXml)

			Replace FTE_Xml With cXml In DoRig

		EndIf



	EndIf

	

EndIf



ENDPROC

PROCEDURE fepa_get

** Leggo i dati del record successivo



If Thisform.FepaEnabled



	This.oCaller.oFtexml.RDOC_XMLToCursor(DoRig.Fte_xml)



	Iif(Thisform.FepaSchema = 1, This.Fepa_Get_OA_Data(), .T.)



	This.Fepa_Get_DG_Data()



	If Thisform.FepaSchema = 1

	

		This.PF.pgFEPA.PFX.pgAltri.Grid_RDOC1.RestoreRecordSource()

		This.PF.pgFEPA.PFX.pgCodice.Grid_RDOC2.RestoreRecordSource()



	EndIf

	

	Iif(Thisform.FepaSchema = 1, This.PF.pgFEPA.Refresh(), This.PF.pgSemplificata.Refresh())

	

EndIf

ENDPROC

PROCEDURE fepa_setuitag

If Thisform.FepaSchema = 1



With ThisForm.PF.pgFEPA.PFX.PgDati



Thisform.Fepa_SetUITagObj(.txtDataInizio.Label,			'2.2.1.7')

Thisform.Fepa_SetUITagObj(.TxtDataFine.Label,			'2.2.1.8')

Thisform.Fepa_SetUITagObj(.TxtRiferimentoAmm.Label,	'2.2.1.15')



EndWith



With ThisForm.PF.pgFEPA.PFX.pgAltri



	.Caption = .Caption + ' (2.2.1.16)'

	

	With .Grid_RDOC1



	.Headerheight = .Headerheight * 2



	Thisform.Fepa_SetUITagObj(.ColTipoDato.Controls(1),	'2.2.1.16.1')

	Thisform.Fepa_SetUITagObj(.ColRifTesto.Controls(1),	'2.2.1.16.2')

	Thisform.Fepa_SetUITagObj(.ColRifNumero.Controls(1),	'2.2.1.16.3')

	Thisform.Fepa_SetUITagObj(.ColRifData.Controls(1),		'2.2.1.16.4')

	

	EndWith

	

EndWith



With ThisForm.PF.pgFEPA.PFX.pgCodice



	.Caption = .Caption + ' (2.2.1.3)'

	

	With .Grid_RDOC2



	.Headerheight = .Headerheight * 2



	Thisform.Fepa_SetUITagObj(.ColCodiceTipo.Controls(1),		'2.2.1.3.1')

	Thisform.Fepa_SetUITagObj(.ColCodiceValore.Controls(1),	'2.2.1.3.2')

	

	EndWith



EndWith



With ThisForm.PF.pgFEPA.PFR



Thisform.Fepa_SetUITagObj(.PGO.CntRead.txtIdDocumento.Label,	'2.1.2.2')

Thisform.Fepa_SetUITagObj(.PGO.CntRead.txtData.Label,				'2.1.2.3')

Thisform.Fepa_SetUITagObj(.PGO.CntRead.TxtNumItem.Label,			'2.1.2.4')

Thisform.Fepa_SetUITagObj(.PGO.CntRead.txtCommessa.Label,		'2.1.2.5')

Thisform.Fepa_SetUITagObj(.PGO.CntRead.TxtCup.Label,				'2.1.2.6')

Thisform.Fepa_SetUITagObj(.PGO.CntRead.TxtCig.Label,				'2.1.2.7')



Thisform.Fepa_SetUITagObj(.PGO.CntData.txtIdDocumento.Label,	'2.1.2.2')

Thisform.Fepa_SetUITagObj(.PGO.CntData.txtData.Label,				'2.1.2.3')

Thisform.Fepa_SetUITagObj(.PGO.CntData.TxtNumItem.Label,			'2.1.2.4')

Thisform.Fepa_SetUITagObj(.PGO.CntData.txtCommessa.Label,		'2.1.2.5')

Thisform.Fepa_SetUITagObj(.PGO.CntData.TxtCup.Label,				'2.1.2.6')

Thisform.Fepa_SetUITagObj(.PGO.CntData.TxtCig.Label,				'2.1.2.7')



Thisform.Fepa_SetUITagObj(.PGC.CntData.txtIdDocumento.Label,	'2.1.3.2')

Thisform.Fepa_SetUITagObj(.PGC.CntData.txtData.Label,				'2.1.3.3')

Thisform.Fepa_SetUITagObj(.PGC.CntData.TxtNumItem.Label,			'2.1.3.4')

Thisform.Fepa_SetUITagObj(.PGC.CntData.txtCommessa.Label,		'2.1.3.5')

Thisform.Fepa_SetUITagObj(.PGC.CntData.TxtCup.Label,				'2.1.3.6')

Thisform.Fepa_SetUITagObj(.PGC.CntData.TxtCig.Label,				'2.1.3.7')



Thisform.Fepa_SetUITagObj(.PGV.CntData.txtIdDocumento.Label,	'2.1.4.2')

Thisform.Fepa_SetUITagObj(.PGV.CntData.txtData.Label,				'2.1.4.3')

Thisform.Fepa_SetUITagObj(.PGV.CntData.TxtNumItem.Label,			'2.1.4.4')

Thisform.Fepa_SetUITagObj(.PGV.CntData.txtCommessa.Label,		'2.1.4.5')

Thisform.Fepa_SetUITagObj(.PGV.CntData.TxtCup.Label,				'2.1.4.6')

Thisform.Fepa_SetUITagObj(.PGV.CntData.TxtCig.Label,				'2.1.4.7')



Thisform.Fepa_SetUITagObj(.PGR.CntData.txtIdDocumento.Label,	'2.1.5.2')

Thisform.Fepa_SetUITagObj(.PGR.CntData.txtData.Label,				'2.1.5.3')

Thisform.Fepa_SetUITagObj(.PGR.CntData.TxtNumItem.Label,			'2.1.5.4')

Thisform.Fepa_SetUITagObj(.PGR.CntData.txtCommessa.Label,		'2.1.5.5')

Thisform.Fepa_SetUITagObj(.PGR.CntData.TxtCup.Label,				'2.1.5.6')

Thisform.Fepa_SetUITagObj(.PGR.CntData.TxtCig.Label,				'2.1.5.7')



Thisform.Fepa_SetUITagObj(.PGL.CntData.txtIdDocumento.Label,	'2.1.6.2')

Thisform.Fepa_SetUITagObj(.PGL.CntData.txtData.Label,				'2.1.6.3')

Thisform.Fepa_SetUITagObj(.PGL.CntData.TxtNumItem.Label,			'2.1.6.4')

Thisform.Fepa_SetUITagObj(.PGL.CntData.txtCommessa.Label,		'2.1.6.5')

Thisform.Fepa_SetUITagObj(.PGL.CntData.TxtCup.Label,				'2.1.6.6')

Thisform.Fepa_SetUITagObj(.PGL.CntData.TxtCig.Label,				'2.1.6.7')



Thisform.Fepa_SetUITagObj(.PGD.CntRead.txtIdDocumento.Label,	'2.1.8.1')

Thisform.Fepa_SetUITagObj(.PGD.CntRead.txtData.Label,				'2.1.8.2')



Thisform.Fepa_SetUITagObj(.PGD.CntData.txtIdDocumento.Label,	'2.1.8.1')

Thisform.Fepa_SetUITagObj(.PGD.CntData.txtData.Label,				'2.1.8.2')



EndWith



Else



With ThisForm.PF.pgSemplificata.PFX.PgDati



Thisform.Fepa_SetUITagObj(.txtImporto.Label,		'2.2.2')

Thisform.Fepa_SetUITagObj(.txtImposta.Label,		'2.2.3.1')



EndWith



EndIf



ENDPROC

PROCEDURE fepa_setuitagobj

Lparameters oCtrl, cTag



If PemStatus(oCtrl, 'Caption', 5) And !Empty(cTag)



	Do Case

	

	Case Upper(oCtrl.BaseClass) == 'HEADER'



		oCtrl.WordWrap 	= .T.

		oCtrl.Alignment	= 2		&& middle Center

		oCtrl.Caption 		= oCtrl.Caption + Chr(13) + ' (' + cTag + ')'



	Otherwise

	

		oCtrl.Caption = oCtrl.Caption + ' (' + cTag + ')'



	EndCase



EndIf







ENDPROC

PROCEDURE fepa_schema

Return ICase(	!This.Fepa_Enabled(), 0, ;

					!This.oCaller.Fte_Semplificata(), 1, ;

					2)



ENDPROC

PROCEDURE onrefresh

DoDefault()



** Questo codice è in relazione con quello nell'Init del container pgRighe

** e con quello nel Grid_When dello stesso container pgRighe



With This.PF.pgGenerale



	If oApp.UserRightLevel >= RL_POWER_USER

		.txtFattoreToUM1.Field.ReadOnly = (This.Mode == FEDIMODE_SHOW)

		.txtQta.Field.ReadOnly 			  = (This.Mode == FEDIMODE_SHOW)

		.txtQtaEvasa.Field.ReadOnly	  = (This.Mode == FEDIMODE_SHOW)

		.txtQtaEvadibile.Field.ReadOnly = (This.Mode == FEDIMODE_SHOW)

	Else

		.txtFattoreToUM1.Field.ReadOnly = (This.Mode == FEDIMODE_SHOW Or Iif(!InList(DoTes.TipoDocumento, 'A', 'F', 'N' ), DoRig.Qta != DoRig.QtaEvadibile, .F.) And oApp.UserRightLevel < RL_POWER_USER)

		.txtQta.Field.ReadOnly 			  = (This.Mode == FEDIMODE_SHOW Or Iif(!InList(DoTes.TipoDocumento, 'A', 'F', 'N' ), DoRig.Qta != DoRig.QtaEvadibile, .F.) And oApp.UserRightLevel < RL_POWER_USER)

		.txtQtaEvasa.Field.ReadOnly	  = .T.

		.txtQtaEvadibile.Field.ReadOnly = .T.

	EndIf

	.txtCd_AR.Field.ReadOnly = (	Thisform.Mode == FEDIMODE_SHOW Or !IsEmpty(DoRig.Id_DoRig_Evade) Or Lower(DoRig.TipoRigaRif) == 'r'   )		&& Codice gemello in Ctrl_When di pgRighe

	

	.btnDoDb.Enabled = !IsEmpty(DoRig.Cd_AR) And (!IsEmpty(DoRig.Id_DoDB) Or Thisform.Mode != FEDIMODE_SHOW)

	

	.Cnt_RR.txtRR_Cd_CGConto.Visible = .Cnt_RR.txtRR_Cd_CGConto.Field.When()

	.Cnt_RR.Title.Caption = Iif(.Cnt_RR.txtRR_Cd_CGConto.Visible, ' Ratei e risconti', ' Competenza')

	

	.Cnt_RR.Visible = (.Cnt_RR.txtRR_Cd_CGConto.Visible Or This.Parameters.ParentGrid.ColRR_DataInizio.Visible)



	** Lo skip di record con la toolbar non sposta il fuoco dal campo per cui al cambio di record bisogna verificare

	** che il controllo corrente permetta la ricezione de fuoco (When()) contestualmente al record corrente ed eventualmente spostarlo,

	** altrimenti si rischia di dare la possibilità di inserire dati in campi non abilitati.



	If Type('ThisForm.ActiveControl') == 'O'

		Local oControl

		oControl = ThisForm.ActiveControl

		Iif(Pemstatus(oControl, 'When', 5) And !oControl.When(), Thisform.Title_Bar.SetFocus(), .T.)

	EndIf



EndWith



ENDPROC

PROCEDURE Show

LParameters nStyle



DoDefault(nStyle)



This.Visible = This.Visible && necessario perchè altrimenti in alcuni casi la form risulta non visibile e questo dà problemi alla chiusura della form principale



Local lPackList, lMatricole, nDelta

Local oRecDo



oRecDo = This.Parameters.ParentForm.PF.pgGenerale.txtCd_Do.Field.FKRecord



With This.PF.pgGenerale



	lMatricole = oRecDo.MtrEnabled

	lPackList  = oRecDo.PkLstEnabled And oRecDo.PkLstMode = 2



	.txtCd_AR.Field.CheckFor = AtC(Left(DoTes.Cd_Cf, 1), 'CF')



	.txtMatricole.Visible	= lMatricole

	.txtPackingList.Visible	= lPackList



	.txtPackList.Visible    = oRecDo.PkLstEnabled And oRecDo.PkLstMode = 1



	If !lMatricole

		nDelta = .txtPackingList.Left - .txtMatricole.Left

		ObjMov(.txtPackingList, .txtPackingList.Left - nDelta)

		ObjMov(.txtNote, .txtNote.Left - nDelta, .txtNote.Top, .txtNote.Width + nDelta, .txtNote.Height)

	EndIf



	If !lPackList

		nDelta = .txtNote.Left - .txtPackingList.Left

		ObjMov(.txtNote, .txtNote.Left - nDelta, .txtNote.Top, .txtNote.Width + nDelta, .txtNote.Height)

	EndIf



EndWith



ENDPROC

PROCEDURE cmdbackward

If !Bof('DoRig')



	If This.Mode != FEDIMODE_SHOW And !This.Validate()

		Return .F.

	EndIf



	This.PF.pgGenerale.txtMatricole.Grid.SaveRecordSource()

	This.oCaller.oMatricole.CursorToXml(This.Mode == FEDIMODE_SHOW)



	** Riporto i dati nel campo XML

	This.Fepa_Set()

	

	DoDefault()



	** BUG 2983 - Devo invocare il gotfocus se mi sposto di record in record

	If This.Mode != FEDIMODE_SHOW And Type('This.ActiveControl') = 'O' And PemStatus(This.ActiveControl, 'GotFocus', 5)

		This.ActiveControl.GotFocus()

	EndIf   

	

	This.oCaller.oMatricole.XmlToCursor()

	This.PF.pgGenerale.txtMatricole.Grid.RestoreRecordSource()			

	

	Go Top In DoRigPackList



	This.PF.pgGenerale.txtMatricole	.Grid.Refresh()

	This.PF.pgGenerale.txtPackingList.Grid.Refresh()



	** Leggo i dati del record successivo

	This.Fepa_Get()



	Select DoRig

	

EndIf









ENDPROC

PROCEDURE cmdforward

If !Eof('DoRig')



	If This.Mode != FEDIMODE_SHOW And !This.Validate()

		Return .F.

	EndIf



	This.PF.pgGenerale.txtMatricole.Grid.SaveRecordSource()

	This.oCaller.oMatricole.CursorToXml(This.Mode == FEDIMODE_SHOW)



	** Riporto i dati nel campo XML

	This.Fepa_Set()

	

	DoDefault()



	** BUG 2983 - Devo invocare il gotfocus se mi sposto di record in record

	If This.Mode != FEDIMODE_SHOW And Type('This.ActiveControl') = 'O' And PemStatus(This.ActiveControl, 'GotFocus', 5)

		This.ActiveControl.GotFocus()

	EndIf  



	This.oCaller.oMatricole.XmlToCursor()

	This.PF.pgGenerale.txtMatricole.Grid.RestoreRecordSource()			

	

	Go Top In DoRigPackList



	This.PF.pgGenerale.txtMatricole	.Grid.Refresh()

	This.PF.pgGenerale.txtPackingList.Grid.Refresh()



	** Leggo i dati del record successivo

	This.Fepa_Get()

	

	Select DoRig

	

EndIf



ENDPROC

PROCEDURE settitlevalue

LParameters cTitle



cTitle = ThisForm.PF.CurrentPage.Caption



DoDefault(cTitle)





ENDPROC

PROCEDURE Init

Local cPicQta, cPicPrz, cPicPrzUn, AliasVL, AliasDO, lShowMode

Local nWA, oPg, cFilter, nDelta

Local nDecPrzUn



** Assegnando lo stato enabled prima del dodefault le faccio scomparire anche dal menu VIEW

** ----- LICADAPTER



** This.Parameters.ParentForm

Iif(!oApp.LicInfo.CA_Main, ThisForm.PF.PGCoan.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply), .T.)

Iif(!oApp.LicInfo.Allegati, ThisForm.PF.PGAllegati.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply), .T.)



If !DoDefault()

	Return .F.

Endif



lShowMode = (Thisform.Mode == FEDIMODE_SHOW)



nWA = Select(0)

cPicQta = This.oCaller.DE.Preferenza.PicSepQta

AliasVL = This.oCaller.PF.pgGenerale.txtCd_VL.Field.FKAlias

AliasDO = This.oCaller.PF.pgGenerale.txtCd_DO.Field.FKAlias



If !IsEmpty(AliasVL)

	cPicPrz	 = Eval(AliasVL + '.PicSep')

	cPicPrzUn = Eval(AliasVL + '.PicSepPrzUn')

	nDecPrzUn = Eval(AliasVL + '.DecimaliPrzUn')

Endif



With Thisform



	.AddProperty('CallerCntGrid', This.oCaller.PF.pgGenerale.PF.pgRighe.Cnt)

	.AddProperty('Ditta'			 , This.oCaller.Ditta							  )



	With .PF.pgGenerale

		.txtQta.Field.InputMask 							= cPicQta

		.txtQtaEvasa.Field.InputMask 						= cPicQta

		.txtQtaEvadibile.Field.InputMask 				= cPicQta

		.txtPackingList.Grid.AllowAddNew					= !lShowMode

		.txtPackingList.Grid.ColQta.Text1.InputMask	= cPicQta

		.txtPackingList.Grid.ColQta.Sparse 				= .F.

		.txtPrezzoUnitarioV.Field.InputMask 			= cPicPrzUn

		.txtPrezzoAddizionaleV.Field.InputMask 		= cPicPrzUn + ICase(nDecPrzUn < 7, '##', nDecPrzUn = 7, '#', '') &&--> come trigger DoRig

		.txtPrezzoTotaleV.Field.InputMask 				= cPicPrz

	Endwith



	** Sono campi anche dipendenti dai moduli ma invece che testare la prop dell'oapp

	** sincronizzo i campi in base alle col della grid

	With This.Parameters.ParentGrid

		oPg = This.PF.pgGenerale

		

		oPg.txtCd_AR.Field.ArticoliObsoleti	= .ColCd_AR.stdText1.ArticoliObsoleti

		

		oPg.txtTipoPC.Visible = .ColTipoPC.Visible

		If !oPg.txtTipoPC.Visible

			nDelta = oPg.txtCd_AR.Left - oPg.txtTipoPC.Left

			oPg.txtCd_AR.Left  		 = oPg.txtCd_AR.Left 		 - nDelta

			oPg.txtCd_AR.Width 		 = oPg.txtCd_AR.Width 		 + nDelta

			oPg.txtCd_AR.Field.Width = oPg.txtCd_AR.Field.Width + nDelta

		EndIf

		

		oPg.txtCd_MG_A.Enabled 					= .ColCd_MG_A.Enabled

		oPg.txtCd_MG_A.Visible 					= .ColCd_MG_A.Visible

		oPg.txtCd_MG_P.Enabled 					= .ColCd_MG_P.Enabled

		oPg.txtCd_MG_P.Visible 					= .ColCd_MG_P.Visible

		oPg.txtCd_MG_A.Field1.Visible 		= .ColCd_MGUbicazione_A.Visible

		oPg.txtCd_MG_P.Field1.Visible 		= .ColCd_MGUbicazione_P.Visible



		oPg.txtDataConsegna.Field.Enabled	= .ColDataConsegna.Enabled

		

		oPg.txtCd_DOSottoCommessa.Visible	= .ColCd_DOSottoCommessa.Visible

		oPg.txtCd_ARLotto.Visible				= .ColCd_ARLotto.Visible

		oPg.txtCd_CGConto.Visible				= .ColCd_CGConto.Visible



		oPg.txtId_MGMov_Carico.Visible		= .ColId_MGMov_Carico.Visible

		** ----- LICADAPTER

		If !oApp.LicInfo.DO_LottiMatr

			oPg.txtMatricole.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

			Thisform.ToolBar.Buttons('MATRICOLAADD').Visible 	= .F.

			Thisform.ToolBar.Buttons('MATRICOLADEL').Visible 	= .F.

		EndIf

		

		If !oApp.LicInfo.Commesse

			oPg.txtCd_DoSottoCommessa.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

		EndIf

		

		If !oApp.LicInfo.CG_Main

			oPg.Cnt_RR.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

		EndIf



		If !(oApp.LicInfo.DO_Ato Or oApp.LicInfo.DB_Varianti)

			oPg.btnDoDB.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

		EndIf

		

	Endwith



	Thisform.SetTitleValue()





**		.CaricaPackingList(DoRig.Id_DoRig)



	** il seguente codice è stato inserito perchè in precedenza per la creazione degli indici si doveva mettere il buffering a 3

	** se erano presenti modifiche, queste venivano perse e i dati non memorizzati

	If RecSignTest(This.oCaller, This.oCaller.DE.DOTes) And This.oCaller.Mode != FEDIMODE_INS_DUP



		Select DoRigPackList

		cFilter = Set("Filter")

		This.oCaller.DE.DoRigPackList.GridBounded = Thisform.PF.pgGenerale.txtPackingList.Grid

		This.oCaller.DE.DoRigPackList.Requery( 'DORig.Id_DOTes = ' + Format4Spt(DOTes.Id_DOTes))

		This.oCaller.DE.DoRigPackList.GridBounded = Null

		This.oCaller.DE.DoRigPackList.Buffering = 3

		This.oCaller.DE.DoRigPackList.MakeIndex('PackListRef', 'Elemento')

		This.oCaller.DE.DoRigPackList.MakeIndex('Id_Dorig')

		This.oCaller.DE.DoRigPackList.MakeIndex('Riga')

		This.oCaller.DE.DoRigPackList.Buffering = 5

		Set Filter To &cFilter

		Go Top In DoRigPackList

		

	Else

	

		Select DoRigPackList

		Go Top In DoRigPackList

		

	Endif



	.PF.pgGenerale.txtMatricole.Grid.AllowAddNew	= !lShowMode

	.PF.pgGenerale.txtMatricole.Grid.ColMatricola.Format	  	 				= '!' + Chrtran(Nvl(Evaluate(This.oCaller.PF.pgGenerale.txtCd_DO.Field.FKAlias + '.MtrFormat'), ''), '!', '')

	.PF.pgGenerale.txtMatricole.Grid.ColMatricola.InputMask					= Nvl(Evaluate(This.oCaller.PF.pgGenerale.txtCd_DO.Field.FKAlias + '.MtrInputMask'), '')

	If !Empty(.PF.pgGenerale.txtMatricole.Grid.ColMatricola.InputMask)

		.PF.pgGenerale.txtMatricole.Grid.ColMatricola.FontName				= 'Courier'

	Endif



	** -----------------------------------------------------------------------------------------------------

	** BUG 2426: Per qualche oscuro motivo, assegnando un valore empty ('') alle property InputMask e Format, 

	**				 il campo colli non risultava editabile (prendeva il fuoco e subito lo perdeva).



	Local cFormat, cInputMask



	cFormat = Evaluate(This.oCaller.PF.pgGenerale.txtCd_DO.Field.FKAlias + '.PkLstFormat')

	If !IsEmpty(cFormat)

		.PF.pgGenerale.txtPackList.Field.Format = cFormat

	EndIf 



	cInputMask = Evaluate(This.oCaller.PF.pgGenerale.txtCd_DO.Field.FKAlias + '.PkLstInputMask')

	If !IsEmpty(cInputMask)

		.PF.pgGenerale.txtPackList.Field.InputMask = cInputMask

	EndIf 

	** --------------------------------------------------------------------------------------------

	

	If !Empty(.PF.pgGenerale.txtPackList.Field.InputMask)

		.PF.pgGenerale.txtPackList.Field.FontName									= 'Courier New'

	Endif



	.PF.pgGenerale.txtPackingList.Grid.ColElemento.Format						= Nvl(Evaluate(This.oCaller.PF.pgGenerale.txtCd_DO.Field.FKAlias + '.PkLstFormat'   ), '')

	.PF.pgGenerale.txtPackingList.Grid.ColElemento.InputMask					= Nvl(Evaluate(This.oCaller.PF.pgGenerale.txtCd_DO.Field.FKAlias + '.PkLstInputMask'), '')

	If !Empty(.PF.pgGenerale.txtPackingList.Grid.ColElemento.InputMask)

		.PF.pgGenerale.txtPackingList.Grid.ColElemento.FontName				= 'Courier New'

	Endif



Endwith



This.PF.PGCoan.Enabled = &AliasDO..CAEnabled

If This.PF.PGCoan.Enabled



	With This.PF.PGCoan

		* combo per CAPartenza e CADurata

		.cmbCAPartenzaEdit.Move(.txtCAPartenza.Left, .TxtCAPartenza.Top)

		.TxtCADurataEdit.Move(.TxtCADurata.Left, .TxtCADurata.Top)

		.TxtCAPartenza.Visible 		= lShowMode

		.cmbCAPartenzaEdit.Visible	= !lShowMode

		.TxtCADurata.Visible 		= lShowMode

		.TxtCADurataEdit.Visible 	= !lShowMode



		.txtDataRif.Field.ControlSource		= "CMonthYearIt(Thisform.oCaller.CA_Datarif())"

		.TxtCAPartenza.Field.ControlSource	= "CMonthYearIt(GoMonth(Thisform.oCaller.CA_Datarif(), DoRig.CAPartenza))"

		.TxtCADurata.Field.ControlSource		= "CMonthYearIt(GoMonth(Thisform.oCaller.CA_Datarif(), DoRig.CAPartenza + DoRig.CADurata - 1))"





		** Il periodo e la durata li visualizzo solo se è impostato a true il flag Preferenza.CACGPeriodo

		If oapp.Preferenza.CACGPeriodo

			.TxtDataInizioComp.Visible			= .T.

			.TxtDataFineComp.Visible			= .T.



			.TxtDataRif.Visible			= .F.

			.TxtCAPartenza.Visible 		= .F.

			.cmbCAPartenzaEdit.Visible	= .F.

			.TxtCADurata.Visible 		= .F.

			.TxtCADurataEdit.Visible 	= .F.

			

			.TxtDataInizioComp.Move(.TxtDataRif.Left, .TxtDataRif.Top)

			.TxtDataFineComp.Move(.TxtDataInizioComp.Left+.TxtDataInizioComp.Width, .TxtDataInizioComp.Top)



		Else

			.TxtDataInizioComp.Visible			= .F.

			.TxtDataFineComp.Visible			= .F.

		EndIf



	EndWith



EndIf



This.PF.pgGenerale.txtPrezzoAddizionaleV.Enabled = !&AliasDO..IvaPerRiga



** Il box per la competenza è visibile in accordo con ciò che si vede nella grid della main form

** Le date inizio/fine sono sempre visibili tranne che in assenza del modulo CG



This.PF.PGGenerale.Cnt_RR.Visible = (&AliasDO..RR_Enabled Or This.Parameters.ParentGrid.ColRR_DataInizio.Visible)

	

If !This.PF.PGGenerale.Cnt_RR.Visible

	nNewH = oPg.Cnt_RR.Bottom - oPg.txtMatricole.Top + 1

	ObjMov(oPg.txtMatricole  , , , , nNewH)	

	ObjMov(oPg.txtPackingList, , , , nNewH)

	ObjMov(oPg.txtNote       , , , , nNewH)

EndIf



** FEPA Section

This.Fepa_SetUIconfig()

This.Fepa_Setcontrolsource()

This.Fepa_SetUITag()



This.Mode = This.oCaller.Mode



**	This.Title_bar.Visible = .T.

**	This.Title_bar.Raised = .T.

**	This.Title_bar.Caption = 'Dettaglio riga'

**	This.Title_bar.TabStop = .F.



**	** ----- LICADAPTER

**	If !oApp.LicInfo.CA_Main

**		WITH Thisform.ToolBar

**			.Buttons('ROWADD'				 ).Visible 	= .F.

**			.Buttons('ROWDEL'				 ).Visible	= .F.

**			.Buttons('ROWINS'				 ).Visible	= .F.

**			.Buttons('ROWUP'  			 ).Visible	= .F.

**			.Buttons('ROWDOWN'			 ).Visible	= .F.

**			.Buttons('PREVIEW'			 ).Visible	= .F.

**			.Buttons('ROWCOPY'			 ).Visible	= .F.

**			.Buttons('ROWPASTE'			 ).Visible	= .F.

**			.Buttons('SEP_BEFORE_ROWWIZ').Visible	= .F.

**			.Buttons('ROWWIZ'			 	 ).Visible	= .F.

**			.Buttons('ROWQUAD'			 ).Visible	= .F.

**			.Buttons('SEP_AFTER_ROWWIZ' ).Visible	= .F.

**		EndWith

**	EndIf



Select (nWA)



ENDPROC

PROCEDURE inittoolbar

DoDefault()



Local lShow, i, oBtn



lShow = (ThisForm.Mode == FEDIMODE_SHOW)

With ThisForm.Toolbar



	oBtn = .Buttons('ROWADD')

	oBtn.Visible		= .T.

	oBtn.Enabled		= !lShow

	oBtn.Image			= 'NEW'

	oBtn.ToolTipText	= 'Aggiungi Riga Documento'

	

	oBtn = .Buttons('ROWDEL')

	oBtn.Visible		= .T.

	oBtn.Enabled		= !lShow

	oBtn.Image			= 'DELETE'

	oBtn.ToolTipText	= 'Elimina Riga Documento'



	oBtn = .Buttons('ROWINS')

	oBtn.Visible		= .T.

	oBtn.Enabled		= !lShow	

	oBtn.Image			= 'NEWDUP'	

	oBtn.ToolTipText	= 'Duplica Riga Documento'



	oBtn = .Buttons('SEP_AFTER_ROWMARK')

	oBtn.Visible		= .T.

	i						= oBtn.Index



	oBtn = .Buttons.Add(i+1, 'MATRICOLAADD',, 1, 'ROWADD')

	oBtn.Visible		= .T.

	oBtn.Enabled		= .F.

	oBtn.ToolTipText	= 'Aggiunta Matricola/Pack List'



	oBtn = .Buttons.Add(i+2, 'MATRICOLADEL',, 1, 'ROWDEL')

	oBtn.Visible		= .T.

	oBtn.Enabled		= .F.

	oBtn.ToolTipText	= 'Eliminazione Matricola/Pack List'



	oBtn = .Buttons('SEP_AFTER_EDITREC')

	oBtn.Visible		= .T.



EndWith







ENDPROC

PROCEDURE mnu_initgridpad

LPARAMETERS cKey



LOCAL cMenuName, cPadName, cPopupName, cForm



cKey = MB_GRID_PAD



WITH THIS

	cForm					= .Name

	cMenuName			= .mnu_GetMenuName ()

	cPadName				= .mnu_GetPadName  (cKey)

	cPopupName			= .mnu_GetPopupName(cKey)

ENDWITH



**------------------------------------------------------------------------------------------------



DEFINE PAD 	(cPadName) OF (cMenuName) PROMPT Thisform.TM_(,"A500F94A-6D48-4047-9FF6-9057931C1204", "\<Righe") COLOR SCHEME 3 KEY ALT+R, "Alt+R" 

ON     PAD 	(cPadName) OF (cMenuName) ACTIVATE POPUP (cPopupName) 

	

DEFINE POPUP (cPopupName) MARGIN RELATIVE SHADOW COLOR SCHEME 4



**------------------------------------------------------------------------------------------------



DEFINE 		 BAR MB_GRID_ADD	 OF (cPopupName) PROMPT Thisform.TM_(,"7FA8D89A-BF43-492C-8624-E9D40D876079", "\<Aggiungi riga Documento")	SKIP FOR !&cForm..Toolbar.IsActive('ROWADD')

ON SELECTION BAR MB_GRID_ADD	 OF (cPopupName) &cForm..DoCmd('RowAdd',,'1')



DEFINE 		 BAR MB_GRID_DEL	 OF (cPopupName) PROMPT Thisform.TM_(,"DA31D6D7-18AD-4F48-A670-E16DE4ED5E8F", "\<Elimina riga Documento")		SKIP FOR !&cForm..Toolbar.IsActive('ROWDEL')

ON SELECTION BAR MB_GRID_DEL	 OF (cPopupName) &cForm..DoCmd('RowDel',,'0')



DEFINE 		 BAR MB_GRID_INS	 OF (cPopupName) PROMPT Thisform.TM_(,"5650B042-2756-419B-A12A-1631D072AF42", "\<Inserisci riga Documento")	SKIP FOR !&cForm..Toolbar.IsActive('ROWINS')

ON SELECTION BAR MB_GRID_INS	 OF (cPopupName) &cForm..DoCmd('RowIns',,'1')







RETURN cPopupName





ENDPROC

PROCEDURE QueryUnload

If !This.QueryExit()

	NoDefault

EndIf



ENDPROC

PROCEDURE cmdexit

LOCAL lOk

lOk = .T.

IF THISFORM.Mode != FEDIMODE_SHOW 

	lOk = This.QueryExit()

ENDIF	

IF lOk

	DODEFAULT()

ENDIF



ENDPROC

PROCEDURE Load

DoDefault()



This.AddProperty('oCaller', 		This.Parameters.ParentForm)

This.AddProperty('FepaEnabled', 	This.Fepa_Enabled())

This.AddProperty('FepaSchema', 	This.Fepa_Schema())



This.oCaller.oMatricole.XmlToCursor()

Iif(Thisform.FepaEnabled, This.oCaller.oFtexml.RDOC_XMLToCursor(DoRig.Fte_Xml), .T.)



ENDPROC

PROCEDURE Unload

** Salvo per sicurezza in quanto potrei aver attivato la form, scritto i dati di una sola riga ed uscito senza muovermi avanti o indietro.

If Thisform.FepaEnabled



	If This.Mode != FEDIMODE_SHOW 



		Local cXml

		cXml = This.oCaller.oFteXml.RDOC_CursorToXML()

		If !SafeCompare(DoRig.FTE_Xml, cXml)

			Replace FTE_Xml With cXml In DoRig

		EndIf



	EndIf



	This.oCaller.oFtexml.RDOC_WA_Destroy()

	

EndIf



RemoveProperty(This, 'oCaller')



Return DoDefault()



ENDPROC

PROCEDURE title_bar.onlabelclick

** da std_FediForm



Local i, nX, nY, oPage, nTmp

Local nTmp, aTmp[1,7]	&& 1 PageOrder, 2 Cation, 3 Command, 4 Disabled



nTmp = 0

For Each oPage In Thisform.PF.Pages

	nTmp = nTmp + 1

	Dimension aTmp[nTmp,7]

	aTmp[nTmp,1] = oPage.PageOrder

	aTmp[nTmp,2] = oPage.Caption

	aTmp[nTmp,3] = 'nPage = ' + Transform(oPage.PageOrder)

	aTmp[nTmp,4] = oPage.PageOrder == Thisform.PF.ActivePage		&& Voce del menu con mark?

	aTmp[nTmp,5] = oPage.PageOrder == Thisform.PF.ActivePage

	aTmp[nTmp,6] = "Images\MnuImages\Generale.bmp"

	aTmp[nTmp,7] = oPage.Enabled && Or oPage.Name == 'pgElenco'

Next



Asort(aTmp, 1)		&& Ordino in base al PageOrder (colonna 1)



Thisform.SCMenu.ClearMenu()



For i = 1 To nTmp

	If aTmp[i,7]

		cClause = Iif(i <= 9, 'Key Alt+' + Tran(i) + ',"Alt+' + Tran(i) + '"', '')

		Thisform.SCMenu.AddMenuBar(aTmp[i,2],aTmp[i,3],cClause,,aTmp[i,4],aTmp[i,5], ,aTmp[i,6])

	EndIf 

Next



Thisform.CurrentX  = Objtoclient(This, 2)					&& Left

Thisform.CurrentY  = Objtoclient(This, 1) + This.Height

Thisform.ScaleMode = 0

nX = Thisform.CurrentX

nY = Thisform.CurrentY

Thisform.ScaleMode = 3



Private nPage

nPage = 0



Thisform.SCMenu.ShowMenu(nY,nX)



If nPage > 0

	Thisform.PF.ActivePage = nPage

Endif



ENDPROC

PROCEDURE title_bar.onvisiblechange

** da std_FediForm



Local nDeltaX



With ThisForm.PF

	If This.Visible

		This.Caption	= .CurrentPage.Caption

		nDeltaX 			= .Height - .PageHeight

		.Tabs 			= .F.

		.SpecialEffect = 2	&& Flat

		.BorderWidth 	= 0

		ObjMov(ThisForm.PF, .Left + 1, .Top + nDeltaX - 2, .Width - 2, .Height - nDeltaX)

	Else

		.Tabs 			= .T.

		nDeltaX 			= .Height - .PageHeight

		ObjMov(ThisForm.PF, .Left - 1, .Top - nDeltaX + 2, .Width + 2, .Height + nDeltaX)

	EndIf



EndWith







ENDPROC

PROCEDURE PF.pgAllegati.Init

This.AddProperty('IgnoreDynamicPageInitAll', .T.)



If DmsActivated()

	This.AddProperty('Dms')

	This.Caption = 'DMS'

	This.LongCaption = 'DMS'

EndIf 



DoDefault()

ENDPROC

PROCEDURE PF.dynamicpageinit

Lparameters oPage



If oPage.ControlCount = 0



	If Lower(oPage.Name) == 'pgallegati'



		If Pemstatus(oPage, 'Dms', 5)



			Dms_PgAllegatiInit(oPage, 'DORIG', 'DORig.Id_DORig')



		Endif

	Endif

Endif



ENDPROC

PROCEDURE PF.onpageactivate

LPARAMETERS oPage, nOldpage, lJustRefreshed



DoDefault(oPage, nOldpage, lJustRefreshed)



This.Parent.SetTitleValue()



If Thisform.FepaEnabled



	Local oPage



	oPage = Iif(Thisform.FepaSchema = 1, This.PgFepa, This.PgSemplificata)



	If oPage.PFX.ActivePage = 1



		This.Parent.Fepa_Get_DG_Data()

		oPage.PFX.pgDati.txtQta.Field.Refresh()

		oPage.PFX.pgDati.Refresh()

	

	EndIf

	

EndIf



ENDPROC


*======================================================================

*** CLASS / OBJECT: TxtId_MGMov_Carico (BaseClass: container, Parent: detail.PF.pgGenerale) ***
*** PROPERTIES ***
Top = 42

Left = 379

Width = 92

Height = 30

TabIndex = 8

ZOrderSet = 1

Name = "TxtId_MGMov_Carico"

Label.Comment = "959D5378-2160-4F2D-B360-410D122562C1"

Label.Caption = "Rif. ID Carico"

Label.Name = "Label"


*** METHODS ***
PROCEDURE Refresh

If !DoDefault()

	Return .F.

Endif



Return .T.



LOCAL cPicQta

cPicQta	= RIGHT(Thisform.Parameters.ParentForm.DE.Preferenza.PicSepQta, 15)



If IsEmpty(DoRig.Id_DoRig_Evade)

	This.Visible = .F.

	This.Field.ToolTipText = ''

	Return

Else

	This.Visible = .T.

Endif



If !IsNull(DoRig.DocEvaso_Cd_DO)

	Local cToolTip 

	Set Textmerge On To MemVar cToolTip NoShow

		\Documento                : <<Dorig.DocEvaso_Cd_DO>> <<Alltrim(Dorig.DocEvaso_NumeroDoc)>> del <<DTOC(Dorig.DocEvaso_DataDoc)>>

		\Riga                           : <<Transform(DoRig.DocEvaso_Riga)>>

		\Q.tà                           : <<Transform(DoRig.DocEvaso_Qta, cPicQta)>> <<Transform(DoRig.DocEvaso_Cd_ArMisura)>>

		\Max Q.tà Evadibile    : <<Transform(DoRig.DocEvaso_QtaEvadibile + DoRig.QtaEvasa_InOrigine, cPicQta)>> <<DoRig.DocEvaso_Cd_ArMisura>>

	If DoRig.QtaEvasa_InOrigine != DoRig.QtaEvasa

		\Q.tà Evasa in origine : <<Transform(DoRig.QtaEvasa_InOrigine, cPicQta)>> <<DoRig.DocEvaso_Cd_ArMisura>>

	EndIf

	Set Textmerge To 

	Set Textmerge Off

	

	This.Field.ToolTipText = cToolTip

	

**		This.Field.ToolTipText = 	'Documento                : ' + Dorig.DocEvaso_Cd_DO + ' ' + Alltrim(Dorig.DocEvaso_NumeroDoc) + ' del ' + DTOC(Dorig.DocEvaso_DataDoc) + CRLF + ;

**									'Riga                           : ' + Transform(DoRig.DocEvaso_Riga) + CRLF +;

**							     	'Q.tà                           : ' + Transform(DoRig.DocEvaso_Qta) + ' ' + Transform(Dorig.DocEvaso_Cd_ArMisura) +  CRLF +;

**							     	'Max Q.tà Evadibile        : '      + Transform(DoRig.DocEvaso_QtaEvadibile + Dorig.QtaEvasa_InOrigine) + ' ' + Transform(Dorig.DocEvaso_Cd_ArMisura) + CRLF +;

**							     	'Q.tà Evasa in origine : '          + Transform(DoRig.QtaEvasa_InOrigine) + ' ' + Transform(Dorig.DocEvaso_Cd_ArMisura)

Endif





ENDPROC


*======================================================================

*** CLASS / OBJECT: txtQtaEvasa (BaseClass: container, Parent: detail.PF.pgGenerale) ***
*** PROPERTIES ***
Top = 42

Left = 286

Width = 92

Height = 30

TabIndex = 8

ZOrderSet = 1

Name = "txtQtaEvasa"

Label.Comment = "959D5378-2160-4F2D-B360-410D122562C1"

Label.Caption = "Quantità Evasa"

Label.Name = "Label"


*** METHODS ***
PROCEDURE Refresh

If !DoDefault()

	Return .F.

Endif



LOCAL cPicQta

cPicQta	= RIGHT(Thisform.Parameters.ParentForm.DE.Preferenza.PicSepQta, 15)



If IsEmpty(DoRig.Id_DoRig_Evade)

	This.Visible = .F.

	This.Field.ToolTipText = ''

	Return

Else

	This.Visible = .T.

Endif



If !IsNull(DoRig.DocEvaso_Cd_DO)

	Local cToolTip 

	Set Textmerge On To MemVar cToolTip NoShow

		\Documento                : <<Dorig.DocEvaso_Cd_DO>> <<Alltrim(Dorig.DocEvaso_NumeroDoc)>> del <<DTOC(Dorig.DocEvaso_DataDoc)>>

		\Riga                           : <<Transform(DoRig.DocEvaso_Riga)>>

		\Q.tà                           : <<Transform(DoRig.DocEvaso_Qta, cPicQta)>> <<Transform(DoRig.DocEvaso_Cd_ArMisura)>>

		\Max Q.tà Evadibile    : <<Transform(DoRig.DocEvaso_QtaEvadibile + DoRig.QtaEvasa_InOrigine, cPicQta)>> <<DoRig.DocEvaso_Cd_ArMisura>>

	If DoRig.QtaEvasa_InOrigine != DoRig.QtaEvasa

		\Q.tà Evasa in origine : <<Transform(DoRig.QtaEvasa_InOrigine, cPicQta)>> <<DoRig.DocEvaso_Cd_ArMisura>>

	EndIf

	Set Textmerge To 

	Set Textmerge Off

	

	This.Field.ToolTipText = cToolTip

	

**		This.Field.ToolTipText = 	'Documento                : ' + Dorig.DocEvaso_Cd_DO + ' ' + Alltrim(Dorig.DocEvaso_NumeroDoc) + ' del ' + DTOC(Dorig.DocEvaso_DataDoc) + CRLF + ;

**									'Riga                           : ' + Transform(DoRig.DocEvaso_Riga) + CRLF +;

**							     	'Q.tà                           : ' + Transform(DoRig.DocEvaso_Qta) + ' ' + Transform(Dorig.DocEvaso_Cd_ArMisura) +  CRLF +;

**							     	'Max Q.tà Evadibile        : '      + Transform(DoRig.DocEvaso_QtaEvadibile + Dorig.QtaEvasa_InOrigine) + ' ' + Transform(Dorig.DocEvaso_Cd_ArMisura) + CRLF +;

**							     	'Q.tà Evasa in origine : '          + Transform(DoRig.QtaEvasa_InOrigine) + ' ' + Transform(Dorig.DocEvaso_Cd_ArMisura)

Endif





ENDPROC


*======================================================================

*** CLASS / OBJECT: txtQtaEvadibile (BaseClass: container, Parent: detail.PF.pgGenerale) ***
*** PROPERTIES ***
Top = 42

Left = 193

Width = 92

Height = 30

TabIndex = 7

ZOrderSet = 2

Name = "txtQtaEvadibile"

Label.Comment = "F02E51AA-434B-4C39-9FFA-741276020C01"

Label.Caption = "Quantità Evadibile"

Label.Name = "Label"


*** METHODS ***
PROCEDURE UIEnable

LPARAMETERS lEnable



LOCAL lVisible

lVisible = .T.

IF lEnable AND EVALUATE(THISFORM.Parameters.ParentForm.PF.pgGenerale.txtCd_DO.FIELD.FKAlias + '.Contabile')

	lVisible = .F.

ENDIF



THIS.Visible = lVisible

ENDPROC


*======================================================================

*** CLASS / OBJECT: txtDescrizione (BaseClass: container, Parent: detail.PF.pgFEPA) ***
*** PROPERTIES ***
Comment = "871764E3-48C0-4638-A5C6-BA33A0F3778B"

Anchor = 10

Top = 6

Left = 119

Width = 403

Height = 30

TabIndex = 5

ZOrderSet = 2

Name = "txtDescrizione"

Label.Comment = "0AC459B9-8C68-4D08-B7AE-513932E24924"

Label.Caption = "Descrizione"

Label.Name = "Label"


*** METHODS ***
PROCEDURE Init

DoDefault()



This.Field.DisabledForeColor = oapp.colordecodedfield

ENDPROC


*======================================================================

*** CLASS / OBJECT: txtDescrizione (BaseClass: container, Parent: detail.PF.pgSemplificata) ***
*** PROPERTIES ***
Comment = "871764E3-48C0-4638-A5C6-BA33A0F3778B"

Anchor = 10

Top = 6

Left = 119

Width = 403

Height = 30

TabIndex = 5

ZOrderSet = 2

Name = "txtDescrizione"

Label.Comment = "0AC459B9-8C68-4D08-B7AE-513932E24924"

Label.Caption = "Descrizione"

Label.Name = "Label"


*** METHODS ***
PROCEDURE Init

DoDefault()



This.Field.DisabledForeColor = oapp.colordecodedfield

ENDPROC


*======================================================================

*** CLASS / OBJECT: Field1 (BaseClass: textbox, Parent: detail.PF.pgGenerale.txtCd_MG_P) ***
*** PROPERTIES ***
ControlSource = "DORig.Cd_MGUbicazione_P"

Height = 19

Left = 50

TabIndex = 3

Top = 12

Width = 80

fktabledesc = Ubicazioni

fkdecodedfield = Descrizione

fkacceptinvalid = .F.

canchangemg = .T.

Name = "Field1"


*** METHODS ***
PROCEDURE fkgetcodmges

Return DOTes.Cd_MGEsercizio



ENDPROC

PROCEDURE fkshowdescription

Lparameters cDescText



With This.Parent 

	cDescText = Rtrim(.Field.FKRecord.Descrizione) + ' / ' + xDefault(cDescText, '** Indefinito **')

	.Display.Caption = cDescText

	DoDefault(cDescText)

EndWith 





ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC

PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE fkgetcodar

Return DORig.Cd_AR



ENDPROC

PROCEDURE fkgetcodmg

Return DORig.Cd_MG_P



ENDPROC

PROCEDURE onvaluepick

LParameters nSearchFormType, xValue4Value, oSelectedRec, lFromCode



** Questo codice viene richiamato la prima volta dal menu (con lFromCode == .F.); la chiamata da menu

** deve essere rigirata nel metodo centralizzato Grid_OnValuePick, che poi provvede a richiamare

** questo metodo, stavolta con lFromCode == .T. in modo da evitare la ricorsione



If !lFromCode

	Return Thisform.CallerCntGrid.Grid_OnValuePick(This, .T., nSearchFormType, xValue4Value, oSelectedRec)

Else

	Return DoDefault(nSearchFormType, xValue4Value, oSelectedRec)

EndIf



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field1 (BaseClass: textbox, Parent: detail.PF.pgGenerale.txtCd_MG_A) ***
*** PROPERTIES ***
ControlSource = "DORig.Cd_MGUbicazione_A"

Height = 19

Left = 50

TabIndex = 3

Top = 11

Width = 80

fktabledesc = Ubicazioni

fkdecodedfield = Descrizione

fkacceptinvalid = .F.

canchangemg = .T.

Name = "Field1"


*** METHODS ***
PROCEDURE fkgetcodmges

Return DOTes.Cd_MGEsercizio



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC

PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE fkshowdescription

Lparameters cDescText



With This.Parent 

	cDescText = Rtrim(.Field.FKRecord.Descrizione) + ' / ' + xDefault(cDescText, '** Indefinito **')

	.Display.Caption = cDescText

	DoDefault(cDescText)

EndWith 





ENDPROC

PROCEDURE fkgetcodar

Return DORig.Cd_AR



ENDPROC

PROCEDURE fkgetcodmg

Return DORig.Cd_MG_A





ENDPROC

PROCEDURE onvaluepick

LParameters nSearchFormType, xValue4Value, oSelectedRec, lFromCode



** Questo codice viene richiamato la prima volta dal menu (con lFromCode == .F.); la chiamata da menu

** deve essere rigirata nel metodo centralizzato Grid_OnValuePick, che poi provvede a richiamare

** questo metodo, stavolta con lFromCode == .T. in modo da evitare la ricorsione



If !lFromCode

	Return Thisform.CallerCntGrid.Grid_OnValuePick(This, .T., nSearchFormType, xValue4Value, oSelectedRec)

Else

	Return DoDefault(nSearchFormType, xValue4Value, oSelectedRec)

EndIf



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field1 (BaseClass: textbox, Parent: pgpiede.CntFattura.txtAcconto) ***
*** PROPERTIES ***
Comment = "620E5360-EA04-4AB3-977E-7B09F8F78DA9"

Alignment = 1

ControlSource = "dotes.AccontoFissoV"

InputMask = "##,###,###.##"

Left = 152

Top = 0

Width = 80

Name = "Field1"


*** METHODS ***
PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If lIsChanged

	If This.Value < 0

		xMessageBox(Thisform.TB_(,'6E11257C-CB1F-4E32-9039-B6165E30890E', "L'acconto fisso non può essere negativo."), MB_ICONSTOP)

		Return 0

	Endif 

Endif 



Return Dodefault(lIsChanged, xOldValue)





ENDPROC


*======================================================================

*** CLASS / OBJECT: Field1 (BaseClass: textbox, Parent: fedi.PF.pgGenerale.PF.pgGenerale.cntPagamento.txtCd_Agente) ***
*** PROPERTIES ***
ControlSource = "dotes.cd_agente_2"

Format = "!"

Height = 19

Left = 128

MaxLength = 3

TabIndex = 3

Top = 0

Width = 40

fkselect = SELECT * FROM Agente WHERE Cd_Agente = <TEXT>

fktabledesc = Agenti

fkdecodedfield = Descrizione

fkhasdisplay = .T.

Name = "Field1"


*** METHODS ***
PROCEDURE onvaluechange

LPARAMETERS xOldValue



THISFORM.EvalScontoCassa()



ENDPROC

PROCEDURE fkshowdescription

LParameters cDescText



This.ToolTipText = RTrim(cDescText)



With This.Parent 

	.Display.Caption     = Nvl(                            .Field.ToolTipText + ' / ', '') +                                  .Field1.ToolTipText

	.Label.ToolTipText   = Nvl(.Field.Value + ' - ', '') + .Field.ToolTipText + CRLF       + Nvl(.Field1.Value + ' - ', '') + .Field1.ToolTipText

	.Display.ToolTipText = Nvl(.Field.Value + ' - ', '') + .Field.ToolTipText + CRLF       + Nvl(.Field1.Value + ' - ', '') + .Field1.ToolTipText

EndWith



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field1 (BaseClass: textbox, Parent: fedi.PF.pgGenerale.PF.pgGenerale.txtNumeroDataRif) ***
*** PROPERTIES ***
Comment = "D9E019DE-EE27-4E2E-81EB-F617B5D69976"

ControlSource = "dotes.datadocrif"

Height = 19

Left = 238

TabIndex = 4

ToolTipText = "Data documento di riferimento"

Top = 21

Width = 63

Name = "Field1"


*** METHODS ***
PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If This.Value > Thisform.PF.pgGenerale.txtDataDoc.Field.Value

	xMessageBox(Thisform.TB_(,"3631606A-2A9F-4E6D-BB07-163906861C29", "La Data del documento di riferimento non può essere posteriore alla data di registrazione"), MB_ICONSTOP)

	Return 0

Endif



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Local cCd_VL, cDoAlias, cMsg



cCd_VL = Thisform.PF.pgGenerale.txtCd_VL.field.Value

cDoAlias = Thisform.PF.pgGenerale.txtCd_DO.Field.FKAlias



IF !(cCd_VL == 'EUR') And !IsEmpty(This.Value) And (Evaluate(cDoAlias + '.TipoDocumento') $ 'FNA') And (Evaluate(cDoAlias + '.CliFor') == 'F')

	Local oRec

	

	oRec = GetFixing_2Obj(cCd_VL, This.Value)



	If !IsNull(oRec.Cambio) And oRec.Cambio != Thisform.PF.pgGenerale.txtCambio.Field.Value



		Text To cMsg NoShow PreText 1+2

			Alla data di riferimento del documento il cambio proposto per %1! (%2!) risulta diverso.

		

			Aggiornare il cambio?

		EndText 



		If xMessageBox(Thisform.TB_(,'3BFDCCED-83BF-405D-8BAF-BDD3A602B775', cMsg, cCd_VL, LTrim(Tran(oRec.Cambio, Thisform.PF.pgGenerale.txtCambio.Field.InputMask))), MB_YESNO + MB_ICONQUESTION) = IDYES 

			Thisform.PF.pgGenerale.txtCambio.Field.SetValue(oRec.Cambio)

			

			If !SafeCompare(Ttod(oRec.DataCambio), This.Value)

				xMessageBox(Thisform.TB_(,'65A13BD5-4F60-4B2F-BAB1-D9D5347CDFE4', "Il cambio proposto per %1! risale al %2!.", cCd_VL, Dtoc(oRec.DataCambio)), MB_OK + MB_ICONINFORMATION)

			EndIf 

		EndIf 

	EndIf 

EndIf



Return DoDefault(xOldValue)

ENDPROC


*======================================================================

*** CLASS / OBJECT: Field1 (BaseClass: textbox, Parent: fedi.PF.pgGenerale.PF.pgGenerale.txtCd_LS) ***
*** PROPERTIES ***
ControlSource = "dotes.cd_ls_2"

Format = "!"

Left = 2

TabIndex = 5

ToolTipText = "Listino Secondario/Generale"

Top = 41

Width = 55

fkselect = SELECT * FROM LS WHERE Cd_LS = <TEXT>

fktabledesc = Listini

fkdecodedfield = Descrizione

fkhasdisplay = .T.

Name = "Field1"


*** METHODS ***
PROCEDURE isvalid

LParameters lIsChanged, xOldValue



Local xRet

xRet = DoDefault(lIsChanged, xOldValue)

If Empty(xRet)

	Return xRet

EndIf



** Controllo se la valuta associata ha un fixing

If !IsEmpty(This.Value) And xSqlExec2Var(Textmerge('Select ExitCode From GetFixing(<<FormatC4Spt(This.FkRecord.Cd_VL)>>, <<FormatD4Spt(DoTes.DataDoc)>>)')) < 0

	xMessageBox(Thisform.TB_(,"1F25D44A-AFAC-4F1D-9DC9-F48B36118468", 'La valuta associata al listino %1! non ha alcun fixing. Non è possibile utilizzare tale listino.', This.Value), 48)

	This.FkShowDescription('')

	Return .F.

EndIf 

ENDPROC

PROCEDURE fkshowdescription

Lparameters cDescText



With This 

	If .FKHasDisplay

		.Parent.Display1.Caption = cDescText

	EndIf

	.ToolTipText = 'Listino Secondario/Generale' + Iif(IsEmpty(cDescText), '', ' - ' + Rtrim(cDescText))

EndWith







ENDPROC


*======================================================================

*** CLASS / OBJECT: txtScontoAddizionale (BaseClass: container, Parent: detail.PF.pgGenerale) ***
*** PROPERTIES ***
Top = 74

Left = 193

Width = 92

TabIndex = 11

ZOrderSet = 13

Name = "txtScontoAddizionale"

Label.Comment = "7275FD57-E049-4F9B-9D36-58897E71C6D1"

Label.Caption = "Sconto Addiz."

Label.Name = "Label"


*** METHODS ***
PROCEDURE Init

DoDefault()



This.Visible = !DoTes.ImportiIvati

ENDPROC


*======================================================================

*** CLASS / OBJECT: txtPrezzoAddizionaleV (BaseClass: container, Parent: detail.PF.pgGenerale) ***
*** PROPERTIES ***
Top = 74

Left = 286

Width = 92

TabIndex = 12

ZOrderSet = 13

Name = "txtPrezzoAddizionaleV"

Label.Comment = "50CB5A78-57F8-40D4-9E05-61FEBBCEF867"

Label.Caption = "Prz. Addizionale"

Label.Name = "Label"


*** METHODS ***
PROCEDURE Init

DoDefault()



This.Visible = !DoTes.ImportiIvati

ENDPROC


*======================================================================

*** CLASS / OBJECT: btnDoDB (BaseClass: commandbutton, Parent: detail.PF.pgGenerale) ***
*** PROPERTIES ***
Comment = "887C7BEF-30BD-4CDF-ABF6-D5E4DF25E9E9"

Top = 177

Left = 432

Height = 59

Width = 92

Picture = ..\images\included\tree1.bmp

Caption = "Distinta"

TabIndex = 25

ZOrderSet = 20

Name = "btnDoDB"


*** METHODS ***
PROCEDURE Refresh

This.FontBold = !IsEmpty(DoRig.Id_DoDb)



** Se lasciassi il DODEFAULT(), il bottone prenderebbe il fuoco!!!

**DODEFAULT()

ENDPROC

PROCEDURE Click

Thisform.CallerCntGrid.Grid_Click(This, .T.)

Activate Window (Thisform.Name)

This.Refresh()







ENDPROC

PROCEDURE Init

If !DoDefault()

	Return .F.

EndIf

This.AddProperty('ControlSource', 'DoRig.Id_DoDB')

SetPictureProp(This, 'Images\Included\Tree1.Bmp')



ENDPROC


*======================================================================

*** CLASS / OBJECT: txtMatricole (BaseClass: textbox, Parent: pgrighe.Grid.colMatricole) ***
*** PROPERTIES ***
Alignment = 2

BorderStyle = 0

Value = Matricole

Margin = 0

ReadOnly = .T.

Name = "txtMatricole"


*** METHODS ***
PROCEDURE readonly_assign

LParameters lNewVal



Return .T.

ENDPROC

PROCEDURE DblClick

Local oForm



If !IsEmpty(DoRig.Cd_AR)

	oForm = RunDetail('Libs\SysForm.vcx', Thisform, This, 'wzdMatricola', 'DoRig', 'Id_DoRig', DoRig.Cd_AR, DoRig.Qta * DoRig.FattoreToUm1, This.Parent.ReadOnly)

	oForm.Show(1)

	oForm = Null

EndIf 

ENDPROC


*======================================================================

*** CLASS / OBJECT: Cnt_RR (BaseClass: container, Parent: detail.PF.pgGenerale) ***
*** PROPERTIES ***
Anchor = 14

Top = 397

Left = 8

Width = 516

Height = 56

TabIndex = 29

Name = "Cnt_RR"


*** METHODS ***
PROCEDURE Init

This.BorderWidth = 0



Return DoDefault()

ENDPROC


*======================================================================

*** CLASS / OBJECT: txtNote (BaseClass: container, Parent: detail.PF.pgGenerale) ***
*** PROPERTIES ***
Anchor = 15

Top = 242

Left = 360

Width = 164

Height = 149

TabIndex = 28

tablerif = DO

controlsource = DoRig.NoteXml

Name = "txtNote"

Field1.Comment = "540DB210-DFB6-4B48-AAB5-371360BE3674"

Field1.Name = "Field1"

Label.Comment = "005547F2-D080-4B58-A04E-79C0B44844D8"

Label.Name = "Label"

grdNote.Column1.HEADER1.Comment = "90A9C7E7-EDA8-4322-A46D-4E5EF8392D47"

grdNote.Column1.HEADER1.FontName = "Segoe UI"

grdNote.Column1.HEADER1.FontSize = 8

grdNote.Column1.HEADER1.Name = "HEADER1"

grdNote.Column1.Text1.FontName = "Segoe UI"

grdNote.Column1.Text1.FontSize = 8

grdNote.Column1.Text1.Name = "Text1"

grdNote.Column1.Comment = "E16D2C39-5D09-4664-AFDE-BD3480B70265"

grdNote.Column1.FontName = "Segoe UI"

grdNote.Column1.FontSize = 8

grdNote.Column1.Name = "Column1"

grdNote.Comment = "FDB6C477-B47A-47DA-AF8F-2F5AEE79DE11"

grdNote.Height = 132

grdNote.Left = 0

grdNote.Top = 16

grdNote.Width = 85

grdNote.Name = "grdNote"

field.Comment = "C4F2E299-F2A9-4C7C-8E13-DD443F6B1056"

field.Height = 132

field.Left = 86

field.Top = 16

field.Width = 78

field.ControlSource = "DoRig.NoteRiga"

field.Name = "field"

Title.Comment = "51AEBC53-CC5D-4B42-B247-5699CF84A6EA"

Title.Width = 164

Title.Name = "Title"


*** METHODS ***
PROCEDURE Init

If !DoDefault()

	Return .F.

EndIf



This.DoBitMask = DoTes.DoBitMask

This.OnRecordChange()



BindEvent(Thisform, 'cmdForward', 	This, 'BeforeCmdSave',  0)	&& prima di cambiare  record, salvo il contenuto della nota corrente

BindEvent(Thisform, 'cmdForward', 	This, 'OnRecordChange', 1)	&& dopo aver cambiato record, riaggiorno le note...



BindEvent(Thisform, 'cmdBackward', 	This, 'BeforeCmdSave',  0) && prima di cambiare  record, salvo il contenuto della nota corrente

BindEvent(Thisform, 'cmdBackward', 	This, 'OnRecordChange', 1) && dopo aver cambiato record, riaggiorno le note...



BindEvent(Thisform, 'cmdExit',		This, 'BeforeCmdSave',  0) && prima di uscire,  salvo il contenuto della nota corrente





ENDPROC

PROCEDURE Field1.When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)

ENDPROC

PROCEDURE Field1.contextmenuproc

Lparameters nCBMId, xPar1



**	nCBMId == CMM_ADD_ITEMS_TO_CONTEXT_MENU	-> xPar1 oggetto oMenu di classe ShortcutMenu 	

**	nCBMId == CMM_ADD_ITEMS_TO_EDIT_PAD			-> xPar1 Edit Popup Name								

**	nCBMId == CMM_PROCESS_CHOICE					-> xPar1 choice id (numerico)							- RetVal .T. se choice id riconosciuta e processata, .f. in caso contrario



Local cXml, cNotaXML

Local oXml, oGNodes, oGNode



Do Case



	Case nCBMId == CMM_ADD_ITEMS_TO_CONTEXT_MENU			&& xPar1 oggetto oMenu di classe ShortcutMenu 



		Local oMenu, oMenu1

		Local lBrwSpc0, lDisabled

		

		DoDefault(nCBMId, xPar1)		

		

		If This.Enabled And !This.ReadOnly And !IsEmpty(DoRig.Cd_AR) 

			oMenu = xPar1



			lBrwSpc0 =  (PemStatus(This, 'BrwSpc0', 5) = .F. Or This.BrwSpc0) And !IsEmpty(Thisform.PF.pgGenerale.txtCd_AR.Field.FKRecord.Note_AR)

			oMenu.AddMenuBar('\-'						 ,	,      						, MB_EDIT_SEP_SEARCH)		



			xSqlExec("Select Id_Nota, Descrizione From Nota Where UsedBy = 'AR' Order by Descrizione", "crNote") 

			

			If Reccount('crNote') = 0

				** Ci sono solo le note principali

				oMenu.AddMenuBar(Thisform.TM_(,"F33ADE8C-5B11-4AD5-A2B5-7DCF64BBF5D2", "Replica note articolo %1!", Rtrim(Thisform.PF.pgGenerale.txtCd_AR.Field.FKRecord.Cd_AR)), , 'Key CTRL+N, "Ctrl+N"', MB_EDIT_SRCHSPEC0,,!lBrwSpc0,, "Images\MnuImages\Copy.bmp")



			Else

				** Esistono NoteXML				



				oMenu1 = oMenu.NewMenu()

				oMenu1.AddMenuBar(Thisform.TM_(,"09B55B24-C9F1-4EF2-BE5B-5F91F99F517B", "Note Principali"), , 'Key CTRL+N, "Ctrl+N"', MB_EDIT_SRCHSPEC0,,!lBrwSpc0)

				

				cXml = Nvl(xSqlExec2Var('Select Convert(Varchar(max), NoteXML) From AR Where Cd_AR = ' + FormatC4Spt(Thisform.PF.pgGenerale.txtCd_AR.Field.Value)), '')				

				oXml = NewDomDocument(cXml)

				oGNodes = oXml.selectNodes('rows/row')



				Select crNote

				Scan

					lDisabled = .T.

					For Each oGNode In oGNodes	

						If Val(Nvl(oGNode.GetAttribute('nota'), 0)) = crNote.Id_Nota

							lDisabled = .F.

							Exit

						EndIf 

					Next 				

					oMenu1.AddMenuBar(crNote.Descrizione, , , 1000 + crNote.Id_Nota,, lDisabled)					

				EndScan

	

				oMenu.AddMenuBar(Thisform.TM_(,"59E36349-CCDA-433B-9C03-7DB1A8A3A02E", "Replica note articolo %1!", Rtrim(Thisform.PF.pgGenerale.txtCd_AR.Field.FKRecord.Cd_AR)), oMenu1,,,,,, "Images\MnuImages\Copy.bmp")

			

			EndIf 

			

			Use In crNote

			

		EndIf

		

		Return .T.



	Case nCBMId == CMM_ADD_ITEMS_TO_EDIT_PAD		&& xPar1 Edit Popup Name 

		

		Local cPopupName, cOnSelCmd, cBrwSpc0, cSkipFor, cForm

		

		DoDefault(nCBMId, xPar1) 	

		

		If This.Enabled And !This.ReadOnly And !IsEmpty(DoRig.Cd_AR)

			cPopupName = xPar1

			cForm		  = Thisform.Name



			cBrwSpc0 = Transform((PemStatus(This, 'BrwSpc0', 5) = .F. Or This.BrwSpc0) And !IsEmpty(Thisform.PF.pgGenerale.txtCd_AR.Field.FKRecord.Note_AR))



			xSqlExec("Select Id_Nota, Descrizione From Nota Where UsedBy = 'AR' Order by Descrizione", "crNote") 

			

			If Reccount('crNote') = 0

				** Ci sono solo le note principali



				DefineBar(999					, cPopupName, [Prompt "\-"])

				DefineBar(MB_EDIT_SRCHSPEC0, cPopupName, [Key Ctrl+N, "Ctrl+N" Prompt &cForm..TM_(,"8E6660C3-D1CA-44BA-B67B-6654CACF95DB", "Replica note articolo") Picture "Images\MnuImages\Copy.bmp"  Skip For !&cBrwSpc0])



				cOnSelCmd =  Sys(1272, This) + '.ContextMenuProc(' + Transform(CMM_PROCESS_CHOICE) + ', ' + Transform(MB_EDIT_SRCHSPEC0) + ')'

				On Selection 	Bar (MB_EDIT_SRCHSPEC0) Of (cPopupName) &cOnSelCmd

			

			Else

				** Esistono NoteXML	



				DefineBar(98, cPopupName, [Prompt "\-"])

				DefineBar(99, cPopupName, [Prompt &cForm..TM_(,"A4CA9F49-07D1-4E3B-8B5B-9BBD0D08ECCD", "Replica note articolo") Picture "Images\MnuImages\Copy.bmp"])



				cSubPopupName = cPopupName + '_99'

				On Bar 99 Of (cPopupName) Activate Popup (cSubPopupName)

				Define Popup (cSubPopupName) Margin Relative Shadow Color Scheme 4



				DefineBar(MB_EDIT_SRCHSPEC0, cSubPopupName, [Key Ctrl+N, "Ctrl+N" Prompt &cForm..TM_(,"0EEDD46C-8AB9-4A73-B8C2-18E48E71D0E9", "Note Principali") Skip For !&cBrwSpc0])			

				cOnSelCmd =  Sys(1272, This) + '.ContextMenuProc(' + Transform(CMM_PROCESS_CHOICE) + ', ' + Transform(MB_EDIT_SRCHSPEC0) + ')'

				On Selection 	Bar (MB_EDIT_SRCHSPEC0) Of (cSubPopupName) &cOnSelCmd



				cXml = Nvl(xSqlExec2Var('Select Convert(Varchar(max), NoteXML) From AR Where Cd_AR = ' + FormatC4Spt(Thisform.PF.pgGenerale.txtCd_AR.Field.Value)), '')

				oXml = NewDomDocument(cXml)

				oGNodes = oXml.selectNodes('rows/row')

								

				Select crNote

				Scan



					cSkipFor = '1=1'

					For Each oGNode In oGNodes	

						If Val(Nvl(oGNode.GetAttribute('nota'), 0)) = crNote.Id_Nota

							cSkipFor = '1=0'

							Exit

						EndIf 

					Next 				



					DefineBar(1000 + crNote.Id_Nota, cSubPopupName, 'Prompt "' + Rtrim(crNote.Descrizione) + '" Skip For ' + cSkipFor)

					cOnSelCmd =  Sys(1272, This) + '.ContextMenuProc(' + Transform(CMM_PROCESS_CHOICE) + ', ' + Transform(1000 + crNote.Id_Nota) + ')'

					On Selection 	Bar (1000 + crNote.Id_Nota) Of (cSubPopupName) &cOnSelCmd

				

				EndScan			



				Use In crNote

			EndIf 



		EndIf

		

		Return .T.

		

	Case nCBMId == CMM_PROCESS_CHOICE						&& xPar1 nChoiceId - Torna .T. nel caso nChoiceId sia stato processato



		Local nChoiceId



		nChoiceId  = xPar1



		Do Case

			Case nChoiceId == MB_EDIT_SRCHSPEC0

				If This.Enabled And !This.ReadOnly And !IsEmpty(DoRig.Cd_AR) And !IsEmpty(Thisform.PF.pgGenerale.txtCd_AR.Field.FKRecord.Note_AR)

					If !IsEmpty(This.Value) And xMessageBox(Thisform.TB_(,"01B6B437-315F-4170-B8C6-4962F4D2EFC9", 'Accodare le note articolo alle note già presenti ?'), MB_YESNO + MB_ICONQUESTION) == IDYES

						This.Value = Nvl(This.Value, '') + CRLF + Thisform.PF.pgGenerale.txtCd_AR.Field.FKRecord.Note_AR

					Else

						This.Value = Thisform.PF.pgGenerale.txtCd_AR.Field.FKRecord.Note_AR

					EndIf

					This.Refresh()

				EndIf 

				Return .T.

			

			Case nChoiceId > 1000

				** Replica di NoteXML

				

				cXml = Nvl(xSqlExec2Var('Select Convert(Varchar(max), NoteXML) From AR Where Cd_AR = ' + FormatC4Spt(Thisform.PF.pgGenerale.txtCd_AR.Field.Value)), '')

				oXml = NewDomDocument(cXml)

				oGNodes = oXml.selectNodes('rows/row')

				For Each oGNode In oGNodes	

					If Val(Nvl(oGNode.GetAttribute('nota'), 0)) = (nChoiceId - 1000)

						cNotaXml = oGNode.Text

						Exit

					EndIf 

				Next 

				

				If This.Enabled And !This.ReadOnly And !IsEmpty(DoRig.Cd_AR) And !IsEmpty(cNotaXML)

					If !IsEmpty(This.Value) And xMessageBox(Thisform.TB_(,"01B6B437-315F-4170-B8C6-4962F4D2EFC9", 'Accodare le note articolo alle note già presenti ?'), MB_YESNO + MB_ICONQUESTION) == IDYES

						This.Value = Nvl(This.Value, '') + CRLF + cNotaXML

					Else

						This.Value = cNotaXML

					EndIf

					This.Refresh()		

				EndIf 

				Return .T.

			

			Otherwise

				Return DoDefault(nCBMId, nChoiceId)

		EndCase

			

EndCase

ENDPROC

PROCEDURE Field1.KeyPress

LParameters nKeyCode, nShiftAltCtrl



If nKeyCode = 14 And nShiftAltCtrl = 2 								&& CTRL + N : Riporta note articolo

	This.ContextMenuProc(CMM_PROCESS_CHOICE, MB_EDIT_SRCHSPEC0)

	NoDefault

	Return .T.

EndIf

ENDPROC

PROCEDURE field.When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)

ENDPROC

PROCEDURE field.KeyPress

LParameters nKeyCode, nShiftAltCtrl



If nKeyCode = 14 And nShiftAltCtrl = 2 								&& CTRL + N : Riporta note articolo

	This.ContextMenuProc(CMM_PROCESS_CHOICE, MB_EDIT_SRCHSPEC0)

	NoDefault

	Return .T.

EndIf

ENDPROC

PROCEDURE field.contextmenuproc

Lparameters nCBMId, xPar1



**	nCBMId == CMM_ADD_ITEMS_TO_CONTEXT_MENU	-> xPar1 oggetto oMenu di classe ShortcutMenu 	

**	nCBMId == CMM_ADD_ITEMS_TO_EDIT_PAD			-> xPar1 Edit Popup Name								

**	nCBMId == CMM_PROCESS_CHOICE					-> xPar1 choice id (numerico)							- RetVal .T. se choice id riconosciuta e processata, .f. in caso contrario



Local cXml, cNotaXML

Local oXml, oGNodes, oGNode



Do Case



	Case nCBMId == CMM_ADD_ITEMS_TO_CONTEXT_MENU			&& xPar1 oggetto oMenu di classe ShortcutMenu 



		Local oMenu, oMenu1

		Local lBrwSpc0, lDisabled

		

		DoDefault(nCBMId, xPar1)		

		

		If This.Enabled And !This.ReadOnly And !IsEmpty(DoRig.Cd_AR) 

			oMenu = xPar1



			lBrwSpc0 =  (PemStatus(This, 'BrwSpc0', 5) = .F. Or This.BrwSpc0) And !IsEmpty(Thisform.PF.pgGenerale.txtCd_AR.Field.FKRecord.Note_AR)

			oMenu.AddMenuBar('\-'						 ,	,      						, MB_EDIT_SEP_SEARCH)		



			xSqlExec("Select Id_Nota, Descrizione From Nota Where UsedBy = 'AR' Order by Descrizione", "crNote") 

			

			If Reccount('crNote') = 0

				** Ci sono solo le note principali

				oMenu.AddMenuBar(Thisform.TM_(,"CC7A07D1-AF55-4FF9-B0AC-0EC5985B544D", "Replica note articolo %1!", Rtrim(Thisform.PF.pgGenerale.txtCd_AR.Field.FKRecord.Cd_AR)),, 'Key CTRL+N, "Ctrl+N"', MB_EDIT_SRCHSPEC0,,!lBrwSpc0,, "Images\MnuImages\Copy.bmp")



			Else

				** Esistono NoteXML				



				oMenu1 = oMenu.NewMenu()

				oMenu1.AddMenuBar(Thisform.TM_(,"7E511906-9C83-47E7-AFAC-D48105180E5B", "Note Principali"), , 'Key CTRL+N, "Ctrl+N"', MB_EDIT_SRCHSPEC0,,!lBrwSpc0)

				

				cXml = Nvl(xSqlExec2Var('Select Convert(Varchar(max), NoteXML) From AR Where Cd_AR = ' + FormatC4Spt(Thisform.PF.pgGenerale.txtCd_AR.Field.Value)), '')

				oXml = NewDomDocument(cXml)

				oGNodes = oXml.selectNodes('rows/row')



				Select crNote

				Scan

					lDisabled = .T.

					For Each oGNode In oGNodes	

						If Val(Nvl(oGNode.GetAttribute('nota'), 0)) = crNote.Id_Nota

							lDisabled = .F.

							Exit

						EndIf 

					Next 				

					oMenu1.AddMenuBar(crNote.Descrizione, , , 1000 + crNote.Id_Nota,, lDisabled)					

				EndScan

	

				oMenu.AddMenuBar(Thisform.TM_(,"75949793-0A8E-433F-9A78-9497AC74F0BA", "Replica note articolo %1!", Rtrim(Thisform.PF.pgGenerale.txtCd_AR.Field.FKRecord.Cd_AR)), oMenu1,,,,,, "Images\MnuImages\Copy.bmp")

			

			EndIf 

			

			Use In crNote

			

		EndIf

		

		Return .T.



	Case nCBMId == CMM_ADD_ITEMS_TO_EDIT_PAD		&& xPar1 Edit Popup Name 

		

		Local cPopupName, cOnSelCmd, cBrwSpc0, cSkipFor, cForm

		

		DoDefault(nCBMId, xPar1) 	

		

		If This.Enabled And !This.ReadOnly And !IsEmpty(DoRig.Cd_AR)

			cPopupName = xPar1

			cForm		  = Thisform.Name



			cBrwSpc0 = Transform((PemStatus(This, 'BrwSpc0', 5) = .F. Or This.BrwSpc0) And !IsEmpty(Thisform.PF.pgGenerale.txtCd_AR.Field.FKRecord.Note_AR))



			xSqlExec("Select Id_Nota, Descrizione From Nota Where UsedBy = 'AR' Order by Descrizione", "crNote") 

			

			If Reccount('crNote') = 0

				** Ci sono solo le note principali



				DefineBar(999					, cPopupName, [Prompt "\-"])

				DefineBar(MB_EDIT_SRCHSPEC0, cPopupName, [Key Ctrl+N, "Ctrl+N" Prompt &cForm..TM_(,"6520FA12-DA4C-484C-9AC1-0F9719B02BB2", "Replica note articolo") Picture "Images\MnuImages\Copy.bmp"  Skip For !&cBrwSpc0])



				cOnSelCmd =  Sys(1272, This) + '.ContextMenuProc(' + Transform(CMM_PROCESS_CHOICE) + ', ' + Transform(MB_EDIT_SRCHSPEC0) + ')'

				On Selection 	Bar (MB_EDIT_SRCHSPEC0) Of (cPopupName) &cOnSelCmd

			

			Else

				** Esistono NoteXML	



				DefineBar(98, cPopupName, [Prompt "\-"])

				DefineBar(99, cPopupName, [Prompt &cForm..TM_(,"73116211-7280-42F4-AD65-4845CB72655F", "Replica note articolo") Picture "Images\MnuImages\Copy.bmp"])



				cSubPopupName = cPopupName + '_99'

				On Bar 99 Of (cPopupName) Activate Popup (cSubPopupName)

				Define Popup (cSubPopupName) Margin Relative Shadow Color Scheme 4



				DefineBar(MB_EDIT_SRCHSPEC0, cSubPopupName, [Key Ctrl+N, "Ctrl+N" Prompt &cForm..TM_(,"9E9D7C4C-7BD9-49DE-BA2F-D7DD5FB61EC6", "Note Principali") Skip For !&cBrwSpc0])			

				cOnSelCmd =  Sys(1272, This) + '.ContextMenuProc(' + Transform(CMM_PROCESS_CHOICE) + ', ' + Transform(MB_EDIT_SRCHSPEC0) + ')'

				On Selection 	Bar (MB_EDIT_SRCHSPEC0) Of (cSubPopupName) &cOnSelCmd



				cXml = Nvl(xSqlExec2Var('Select Convert(Varchar(max), NoteXML) From AR Where Cd_AR = ' + FormatC4Spt(Thisform.PF.pgGenerale.txtCd_AR.Field.Value)), '')

				oXml = NewDomDocument(cXml)

				oGNodes = oXml.selectNodes('rows/row')

								

				Select crNote

				Scan



					cSkipFor = '1=1'

					For Each oGNode In oGNodes	

						If Val(Nvl(oGNode.GetAttribute('nota'), 0)) = crNote.Id_Nota

							cSkipFor = '1=0'

							Exit

						EndIf 

					Next 				



					DefineBar(1000 + crNote.Id_Nota, cSubPopupName, 'Prompt "' + Rtrim(crNote.Descrizione) + '" Skip For ' + cSkipFor)

					cOnSelCmd =  Sys(1272, This) + '.ContextMenuProc(' + Transform(CMM_PROCESS_CHOICE) + ', ' + Transform(1000 + crNote.Id_Nota) + ')'

					On Selection 	Bar (1000 + crNote.Id_Nota) Of (cSubPopupName) &cOnSelCmd

				

				EndScan			



				Use In crNote

			EndIf 



		EndIf

		

		Return .T.

		

	Case nCBMId == CMM_PROCESS_CHOICE						&& xPar1 nChoiceId - Torna .T. nel caso nChoiceId sia stato processato



		Local nChoiceId



		nChoiceId  = xPar1



		Do Case

			Case nChoiceId == MB_EDIT_SRCHSPEC0

				If This.Enabled And !This.ReadOnly And !IsEmpty(DoRig.Cd_AR) And !IsEmpty(Thisform.PF.pgGenerale.txtCd_AR.Field.FKRecord.Note_AR)

					If !IsEmpty(This.Value) And xMessageBox(Thisform.TB_(,"01B6B437-315F-4170-B8C6-4962F4D2EFC9", 'Accodare le note articolo alle note già presenti ?'), MB_YESNO + MB_ICONQUESTION) == IDYES

						This.Value = Nvl(This.Value, '') + CRLF + Thisform.PF.pgGenerale.txtCd_AR.Field.FKRecord.Note_AR

					Else

						This.Value = Thisform.PF.pgGenerale.txtCd_AR.Field.FKRecord.Note_AR

					EndIf

					This.Refresh()

				EndIf 

				Return .T.

			

			Case nChoiceId > 1000

				** Replica di NoteXML

				

				cXml = Nvl(xSqlExec2Var('Select Convert(Varchar(max), NoteXML) From AR Where Cd_AR = ' + FormatC4Spt(Thisform.PF.pgGenerale.txtCd_AR.Field.Value)), '')

				oXml = NewDomDocument(cXml)

				oGNodes = oXml.selectNodes('rows/row')

				For Each oGNode In oGNodes	

					If Val(Nvl(oGNode.GetAttribute('nota'), 0)) = (nChoiceId - 1000)

						cNotaXml = oGNode.Text

						Exit

					EndIf 

				Next 

				

				If This.Enabled And !This.ReadOnly And !IsEmpty(DoRig.Cd_AR) And !IsEmpty(cNotaXML)

					If !IsEmpty(This.Value) And xMessageBox(Thisform.TB_(,"01B6B437-315F-4170-B8C6-4962F4D2EFC9", 'Accodare le note articolo alle note già presenti ?'), MB_YESNO + MB_ICONQUESTION) == IDYES

						This.Value = Nvl(This.Value, '') + CRLF + cNotaXML

					Else

						This.Value = cNotaXML

					EndIf

					This.Refresh()		

				EndIf 

				Return .T.

			

			Otherwise

				Return DoDefault(nCBMId, nChoiceId)

		EndCase

			

EndCase

ENDPROC


*======================================================================

*** CLASS / OBJECT: field (BaseClass: textbox, Parent: detail.PF.pgCOAN.TxtCADurata) ***
*** PROPERTIES ***
Comment = "BE3FE66E-A0CC-480C-B052-B43526AFF776"

Top = 11

Width = 110

Name = "field"


*** METHODS ***
PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC


*======================================================================

*** CLASS / OBJECT: field (BaseClass: textbox, Parent: detail.PF.pgCOAN.TxtCADurataEdit) ***
*** PROPERTIES ***
Comment = "0AA442C9-53CC-4AE6-AF9B-CF2E9834D159"

ControlSource = "DoRig.CADurata"

Height = 19

Left = 0

Top = 11

Width = 72

rangehighvalue = 240

rangelowvalue = 0

Name = "field"


*** METHODS ***
PROCEDURE When

Return DoDefault() And Thisform.CallerCntGrid.Grid_When(This, .T.)



ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf

Return ThisForm.CallerCntGrid.Grid_IsValid(This, .T., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Return Thisform.CallerCntGrid.Grid_OnValueChange(This, .T., xOldValue)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Grid_RDOC1 (BaseClass: grid, Parent: detail.PF.pgFEPA.PFX.pgAltri) ***
*** PROPERTIES ***
ColumnCount = 5

Comment = "90BF35E3-7571-4038-A661-877A452D8C8B"

Anchor = 15

AllowAddNew = .T.

AllowRowSizing = .F.

Height = 119

Left = -1

Panel = 1

RowHeight = 17

TabIndex = 8

Top = -1

Width = 488

HighlightStyle = 2

colnumname = Riga

Name = "Grid_RDOC1"

Stdcolumn1.Comment = "4E8A98E6-2E2A-4AA9-A317-7772954274B5"

Stdcolumn1.FontName = "Segoe UI"

Stdcolumn1.FontSize = 8

Stdcolumn1.ColumnOrder = 2

Stdcolumn1.ControlSource = ""

Stdcolumn1.Width = 52

Stdcolumn1.Name = "ColTipoDato"

Stdcolumn2.Comment = "81B795BA-2E0D-43B4-A3BA-E0584F2BBA88"

Stdcolumn2.FontName = "Segoe UI"

Stdcolumn2.FontSize = 8

Stdcolumn2.HeaderClassLibrary = ..\libs\basectrl.fxp

Stdcolumn2.ColumnOrder = 1

Stdcolumn2.ControlSource = ""

Stdcolumn2.Width = 19

Stdcolumn2.Movable = .F.

Stdcolumn2.ReadOnly = .T.

Stdcolumn2.Name = "ColRiga"

Stdcolumn3.FontName = "Segoe UI"

Stdcolumn3.FontSize = 8

Stdcolumn3.ControlSource = ""

Stdcolumn3.Width = 257

Stdcolumn3.Name = "ColRifTesto"

Stdcolumn4.FontName = "Segoe UI"

Stdcolumn4.FontSize = 8

Stdcolumn4.ControlSource = ""

Stdcolumn4.InputMask = "#####################"

Stdcolumn4.Name = "ColRifNumero"

Stdcolumn5.FontName = "Segoe UI"

Stdcolumn5.FontSize = 8

Stdcolumn5.ControlSource = ""

Stdcolumn5.Name = "ColRifData"


*** METHODS ***
PROCEDURE Init

DoDefault()

This.InitAutoSaveLayout()



ENDPROC

PROCEDURE When

Return DoDefault() And !IsEmpty(DoRig.Descrizione)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Stdtext1 (BaseClass: textbox, Parent: detail.PF.pgFEPA.PFX.pgAltri.Grid_RDOC1.ColRiga) ***
*** PROPERTIES ***
FontSize = 8

BorderStyle = 0

Left = 15

Margin = 0

ReadOnly = .T.

Top = 67

Name = "Stdtext1"


*** METHODS ***
PROCEDURE When

Return DoDefault() And .F.

ENDPROC


*======================================================================

*** CLASS / OBJECT: Stdtext1 (BaseClass: textbox, Parent: detail.PF.pgFEPA.PFX.pgAltri.Grid_RDOC1.ColRifNumero) ***
*** PROPERTIES ***
BorderStyle = 0

Left = 20

Margin = 0

Top = 47

Name = "Stdtext1"


*** METHODS ***
PROCEDURE KeyPress

LParameters nKeyCode, nShiftAltCtrl



Local cVal, cInt, cDec



#Define 	MAXINT	11

#Define 	MAXDEC	08



** nKeyCode < 0 (F2-F12) non deve essere trappato e chr(-?) va in errore

** Tutto ciò che non rientra nelle cifre + .- viene scartato a patto che sia una lettera

** Permetto l'ins del . una sola volta

** Verifico se la parte intera (11) o decimale (8) supera il max consentito e permetto l'utilizzo soltanto di alcuni tasti

** XSD pattern [\-]?[0-9]{1,11}\.[0-9]{2,8}



** And GetKeyState(VK_INSERT) = 0 -> Eventualmente per usare il tasto INS (al momento troppe controindicazioni)



cVal = Alltrim(This.Value)

cInt = Iif(At('.', cVal) != 0, Chrtran(Left(cVal, At('.', cVal)), '.', ''), cVal)

cDec = Chrtran(Substr(cVal, At('.', cVal)), '.', '')



If nKeyCode > 0 And ;

	( ;

		(!(Chr(nKeyCode) $ '0123456789.-') And (Between(nKeyCode, 97, 122) Or nKeyCode = 32)) Or ;

		(Chr(nKeyCode) = '.' And Occurs('.', cVal) != 0) Or ;

		(Chr(nKeyCode) = '-' And (Occurs('-', cVal) != 0 Or This.SelStart > 0)) Or ;

		(((Len(cInt) = MAXINT And This.SelStart <= MAXINT) Or (Len(cDec) = MAXDEC And This.SelStart > MAXINT)) And !InList(nKeyCode, 22, 1, 7, 6, 18, 3, 5, 24, 4, 19, 27, 13, 127, 46, 9)) ;

	)

	NoDefault

Else

	Return DoDefault(nKeyCode, nShiftAltCtrl)

EndIf



#Undef MAXINT

#Undef MAXDEC



ENDPROC


*======================================================================

*** CLASS / OBJECT: Stdtext1 (BaseClass: textbox, Parent: detail.PF.pgFEPA.PFX.pgCodice.Grid_RDOC2.ColRiga) ***
*** PROPERTIES ***
FontSize = 8

BorderStyle = 0

Left = 15

Margin = 0

ReadOnly = .T.

Top = 67

Name = "Stdtext1"


*** METHODS ***
PROCEDURE When

Return DoDefault() And .F.

ENDPROC


*======================================================================

*** CLASS / OBJECT: Stdtext1 (BaseClass: textbox, Parent: pgrighe.Grid.ColDoIntento) ***
*** PROPERTIES ***
FontBold = .F.

FontSize = 8

BorderStyle = 0

Left = 12

Margin = 0

SpecialEffect = 1

Top = 69

ForeColor = 0,0,255

fkselect = Select * From Aliquota Where Cd_Aliquota = <TEXT> And IvaSplit = 0 And Cd_TipoIva In ('181C', '182', '18B2', '192')

Name = "Stdtext1"


*** METHODS ***
PROCEDURE valuepickafter

LParameters nPickType, oPickForm



Dodefault(nPickType, oPickForm)

This.OnValueChange()

ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)

ENDPROC

PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif

Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)





ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)

ENDPROC

PROCEDURE DblClick

If !DoDefault()

	Return .f.

EndIf



Iif(Thisform.Mode != FEDIMODE_SHOW, Thisform.CmdDoIntento('DORIG'), .T.)



ENDPROC

PROCEDURE KeyPress

LParameters nKeyCode, nShiftAltCtrl



If nKeyCode = -5 																&& F6 - Dichiarazione Intento

	This.ContextMenuProc(CMM_PROCESS_CHOICE, MB_EDIT_SRCHSPEC0)	

	NoDefault

	Return .T.

EndIf



Return DoDefault(nKeyCode, nShiftAltCtrl)

ENDPROC

PROCEDURE contextmenuproc

Lparameters nCBMId, xPar1, lFromCode



** Questo codice viene richiamato la prima volta dal menu (con lFromCode == .F.); la chiamata da menu

** deve essere rigirata nel metodo centralizzato Grid_ContextMenuProc,  che poi provvede a richiamare

** questo metodo, stavolta con lFromCode == .T. in modo da evitare la ricorsione



If !lFromCode

	Return This.Parent.Parent.Parent.Grid_ContextMenuProc(This, .F., nCBMId, xPar1)

Else

	Return DoDefault(nCBMId, xPar1)

EndIf

ENDPROC

PROCEDURE tooltiptext_access

Local cText



cText = Iif(!IsEmpty(DoRig.Dointento), Thisform.oDoIntento.Tooltiptext_Decode(DoRig.Dointento), DoDefault())

Return cText





ENDPROC

PROCEDURE fkselect_access

Return 	"Select * From Aliquota Where Aliquota.Cd_Aliquota = <TEXT> And Aliquota.IvaSplit = 0 And Aliquota.Cd_TipoIva In ('181C', '182', '18B2', '192')"





ENDPROC

PROCEDURE Click

If !DoDefault()

	Return .f.

EndIf



Iif(Thisform.Mode = FEDIMODE_SHOW, Thisform.CmdDoIntento('DORIG'), .T.)

ENDPROC


*======================================================================

*** CLASS / OBJECT: Stdtext1 (BaseClass: textbox, Parent: pgpiede.CntFattura.Grid.ColDoIntento) ***
*** PROPERTIES ***
FontSize = 8

BorderStyle = 0

Left = 9

Margin = 0

SpecialEffect = 1

Top = 40

ForeColor = 0,0,255

fkselect = SELECT * FROM Aliquota WHERE Cd_Aliquota = <TEXT>

Name = "Stdtext1"


*** METHODS ***
PROCEDURE contextmenuproc

Lparameters nCBMId, xPar1, xPar2



If (Thisform.Mode = FEDIMODE_SHOW And IsEmpty(DorigSpesa.DoIntento)) Or ;

	(!IsEmpty(Dorigspesa.Cd_Aliquota_e) And !xSQLExec2Bit(Textmerge("Exists(Select * From Aliquota Where Cd_Aliquota = <<FormatC4SPT(DorigSpesa.Cd_Aliquota_e)>> And Cd_TipoIva In ('181C', '182', '18B2', '192'))")))

	Return DoDefault(nCBMId, xPar1, xPar2)

EndIf



Do Case



	Case nCBMId == CMM_ADD_ITEMS_TO_CONTEXT_MENU			&& xPar1 oggetto oMenu di classe ShortcutMenu 



		Local oMenu



		oMenu = xPar1

		

		DoDefault(nCBMId, xPar1, xPar2)	

		

		** Nota: utilizzo i #define di tipo SRCHSPEC? anche se si tratta di comandi e non di ricerche

		

		oMenu.AddMenuBar('\-',,, MB_EDIT_SEP_SEARCH2)	

		oMenu.AddMenuBar(Thisform.TM_(,"20731203-B1BE-4F7C-94A4-874141DF8F1B", "Dichiarazioni Intento"),, 'Key Alt+0, "F6"', MB_EDIT_SRCHSPEC0,, .F.,, "Images\MnuImages\Partitario.bmp")				



		Return .T.



	Case nCBMId == CMM_ADD_ITEMS_TO_EDIT_PAD		&& xPar1 Edit Popup Name 



		Local cPopupName, cOnSelCmd



		cPopupName = xPar1

		cForm		  = Thisform.Name



		DoDefault(nCBMId, xPar1, xPar2)



		** Nota: utilizzo i #define di tipo SRCHSPEC? anche se si tratta di comandi e non di ricerche



		Define Bar (MB_EDIT_SEP_SEARCH2) Of (cPopupName) Prompt "\-"

		DefineBar(MB_EDIT_SRCHSPEC0, cPopupName, [Prompt &cForm..TM_(,"20731203-B1BE-4F7C-94A4-874141DF8F1B", "Dichiarazioni Intento") Key Alt+0, "F6" Picture "Images\MnuImages\Partitario.bmp"])

		cOnSelCmd = Sys(1272, This) + '.ContextMenuProc(' + Transform(CMM_PROCESS_CHOICE) + ', Bar())'

		On Selection Bar (MB_EDIT_SRCHSPEC0) Of (cPopupName) &cOnSelCmd				

		

		Return .T.



	Case nCBMId == CMM_PROCESS_CHOICE



		Local nChoiceId



		nChoiceId  = xPar1



		Do Case



			Case nChoiceId == MB_EDIT_SRCHSPEC0



				Thisform.CmdDoIntento('DORIGSPESA')

				Return .T.						



			Otherwise

				Return Dodefault(nCBMId, xPar1, xPar2)

		EndCase



EndCase



ENDPROC

PROCEDURE DblClick

If !DoDefault()

	Return .f.

EndIf



Iif(Thisform.Mode != FEDIMODE_SHOW, Thisform.CmdDoIntento('DORIGSPESA'), .T.)

ENDPROC

PROCEDURE fkselect_access

Return 	"Select * From Aliquota Where Aliquota.Cd_Aliquota = <TEXT> And Aliquota.IvaSplit = 0 And Aliquota.Cd_TipoIva In ('181C', '182', '18B2', '192')"



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



DoDefault(xOldValue)



Iif(!IsEmpty(DoRigSpesa.Cd_Aliquota_e) And IsEmpty(DoRigSpesa.DoIntento) And IsNull(Thisform.DoIntento_Evade('S', DoRigSpesa.Id_Dorigspesa_Evade)), Thisform.CmdDoIntento('DORIGSPESA'), .T.)



If IsEmpty(DoRigSpesa.Cd_Aliquota_e) And !IsEmpty(DoRigSpesa.DoIntento)

	Replace DoIntento With Null In DoRigSpesa

EndIf



AddProperty(This.parent.parent.parent.parent, 'IVA_OnValueChange', .T.)

This.parent.parent.parent.parent.Setdorigspesa_Defaults_IVA()



ENDPROC

PROCEDURE KeyPress

LParameters nKeyCode, nShiftAltCtrl



If nKeyCode = -5 																&& F6 - Dichiarazione Intento

	This.ContextMenuProc(CMM_PROCESS_CHOICE, MB_EDIT_SRCHSPEC0)	

	NoDefault

	Return .T.

EndIf



Return DoDefault(nKeyCode, nShiftAltCtrl)

ENDPROC

PROCEDURE Click

If !DoDefault()

	Return .f.

EndIf



Iif(Thisform.Mode = FEDIMODE_SHOW, Thisform.CmdDoIntento('DORIGSPESA'), .T.)

ENDPROC

PROCEDURE valuepickafter

LParameters nPickType, oPickForm



Dodefault(nPickType, oPickForm)

This.OnValueChange()

ENDPROC

PROCEDURE isvalid

LPARAMETERS lIsChanged, xOldValue



IF !DODEFAULT(lIsChanged, xOldValue)

	RETURN .F.

ENDIF

IF lIsChanged

	RETURN THIS.PARENT.PARENT.PARENT.PARENT.Grid_IsValid(THIS, .F., xOldValue)

ELSE

	RETURN .T.

ENDIF

ENDPROC


*======================================================================

*** CLASS / OBJECT: Stdtext1 (BaseClass: textbox, Parent: pgpiede.CntFattura.Grid.ColDataFineComp) ***
*** PROPERTIES ***
Left = 19

Top = 24

Name = "Stdtext1"


*** METHODS ***
PROCEDURE isvalid

LParameters lIsChanged, xOldValue



IF !DODEFAULT(lIsChanged, xOldValue)

	RETURN .F.

ENDIF



** Data inizio <= Data fine

If (!IsEmpty(DoRigSpesa.DataInizioComp) And !IsEmpty(DoRigSpesa.DataFineComp)) And DoRigSpesa.DataInizioComp > DoRigSpesa.DataFineComp

	xMessageBox(Thisform.TB_(,'0148F45F-2EE1-4343-B73B-B2211032C0EC', 'La data di inizio del periodo di competenza non può essere posteriore a quella di fine.'))

	Return .F.

EndIf



RETURN .T.



ENDPROC


*======================================================================

*** CLASS / OBJECT: btnAdd (BaseClass: commandbutton, Parent: detail.PF.pgFEPA.PFX.pgAltri) ***
*** PROPERTIES ***
Top = 0

Left = 487

Height = 32

Width = 32

Anchor = 9

Picture = ..\images\included\add.bmp

TabIndex = 2

TabStop = .F.

ToolTipText = "Aggiungi riga"

SpecialEffect = 2

PicturePosition = 14

Name = "btnAdd"


*** METHODS ***
PROCEDURE Click

This.Parent.Grid_RDOC1.RowAppend() 

This.Parent.Grid_RDOC1.SetFocus()

ENDPROC


*======================================================================

*** CLASS / OBJECT: btnAdd (BaseClass: commandbutton, Parent: detail.PF.pgFEPA.PFX.pgCodice) ***
*** PROPERTIES ***
Top = 0

Left = 487

Height = 32

Width = 32

Anchor = 9

Picture = ..\images\included\add.bmp

TabIndex = 2

TabStop = .F.

ToolTipText = "Aggiungi riga"

SpecialEffect = 2

PicturePosition = 14

Name = "btnAdd"


*** METHODS ***
PROCEDURE Click

This.Parent.Grid_RDOC2.RowAppend() 

This.Parent.Grid_RDOC2.SetFocus()

ENDPROC


*======================================================================

*** CLASS / OBJECT: btnDel (BaseClass: commandbutton, Parent: detail.PF.pgFEPA.PFX.pgAltri) ***
*** PROPERTIES ***
Top = 31

Left = 487

Height = 32

Width = 32

Anchor = 9

Picture = ..\images\included\deleter.bmp

TabIndex = 3

TabStop = .F.

ToolTipText = "Elimina riga"

SpecialEffect = 2

PicturePosition = 14

Name = "btnDel"


*** METHODS ***
PROCEDURE Click

This.Parent.Grid_RDOC1.RowDelete() 



ENDPROC


*======================================================================

*** CLASS / OBJECT: btnDel (BaseClass: commandbutton, Parent: detail.PF.pgFEPA.PFX.pgCodice) ***
*** PROPERTIES ***
Top = 31

Left = 487

Height = 32

Width = 32

Anchor = 9

Picture = ..\images\included\deleter.bmp

TabIndex = 3

TabStop = .F.

ToolTipText = "Elimina riga"

SpecialEffect = 2

PicturePosition = 14

Name = "btnDel"


*** METHODS ***
PROCEDURE Click

This.Parent.Grid_RDOC2.RowDelete() 



ENDPROC


*======================================================================

*** CLASS / OBJECT: Grid_RDOC2 (BaseClass: grid, Parent: detail.PF.pgFEPA.PFX.pgCodice) ***
*** PROPERTIES ***
ColumnCount = 3

Comment = "6DEA8D80-2851-4602-9423-FC712AD5614C"

Anchor = 15

AllowAddNew = .T.

AllowRowSizing = .F.

Height = 119

Left = -1

Panel = 1

RowHeight = 17

TabIndex = 9

Top = -1

Width = 488

HighlightStyle = 2

colnumname = Riga

Name = "Grid_RDOC2"

Stdcolumn1.Comment = "4E8A98E6-2E2A-4AA9-A317-7772954274B5"

Stdcolumn1.FontName = "Segoe UI"

Stdcolumn1.FontSize = 8

Stdcolumn1.ColumnOrder = 2

Stdcolumn1.ControlSource = ""

Stdcolumn1.Width = 221

Stdcolumn1.Name = "ColCodiceTipo"

Stdcolumn2.Comment = "81B795BA-2E0D-43B4-A3BA-E0584F2BBA88"

Stdcolumn2.FontName = "Segoe UI"

Stdcolumn2.FontSize = 8

Stdcolumn2.HeaderClassLibrary = ..\libs\basectrl.fxp

Stdcolumn2.ColumnOrder = 1

Stdcolumn2.ControlSource = ""

Stdcolumn2.Width = 19

Stdcolumn2.Movable = .F.

Stdcolumn2.ReadOnly = .T.

Stdcolumn2.Name = "ColRiga"

Stdcolumn3.FontName = "Segoe UI"

Stdcolumn3.FontSize = 8

Stdcolumn3.ControlSource = ""

Stdcolumn3.Width = 244

Stdcolumn3.Name = "ColCodiceValore"


*** METHODS ***
PROCEDURE When

Return DoDefault() And !IsEmpty(DoRig.Descrizione)



ENDPROC

PROCEDURE Init

DoDefault()

This.InitAutoSaveLayout()



ENDPROC


*======================================================================

*** CLASS / OBJECT: txtCd_AR (BaseClass: container, Parent: detail.PF.pgFEPA) ***
*** PROPERTIES ***
Comment = "274DF35B-854C-48E7-9DC8-5C14224FACB3"

Top = 6

Left = 3

Width = 113

Height = 30

TabIndex = 4

ZOrderSet = 3

Name = "txtCd_AR"

Label.Comment = "3540AC39-3AD4-485B-8CA8-6F6ABF9E33D4"

Label.Caption = "Articolo"

Label.Name = "Label"


*** METHODS ***
PROCEDURE Init

DoDefault()



This.Field.DisabledForeColor = oapp.colordecodedfield

ENDPROC


*======================================================================

*** CLASS / OBJECT: txtCd_AR (BaseClass: container, Parent: detail.PF.pgSemplificata) ***
*** PROPERTIES ***
Comment = "274DF35B-854C-48E7-9DC8-5C14224FACB3"

Top = 6

Left = 3

Width = 113

Height = 30

TabIndex = 4

ZOrderSet = 3

Name = "txtCd_AR"

Label.Comment = "3540AC39-3AD4-485B-8CA8-6F6ABF9E33D4"

Label.Caption = "Articolo"

Label.Name = "Label"


*** METHODS ***
PROCEDURE Init

DoDefault()



This.Field.DisabledForeColor = oapp.colordecodedfield

ENDPROC


*======================================================================

*** CLASS / OBJECT: TxtNumItem (BaseClass: container, Parent: detail.PF.pgFEPA.PFR.PGO.CntRead) ***
*** PROPERTIES ***
Top = 0

Left = 0

Width = 332

Height = 19

TabIndex = 1

Name = "TxtNumItem"

Label.Comment = "CD40AA88-0C4E-4F56-B491-D36006C7E9D3"

Label.FontUnderline = .T.

Label.Caption = "Rif. riga"

Label.Left = 0

Label.MousePointer = 15

Label.Top = 1

Label.ForeColor = 0,0,255

Label.Name = "Label"


*** METHODS ***
PROCEDURE Label.Click

Local oForm



If !IsEmpty(This.Parent.Id_Dotes) And !IsEmpty(This.Parent.Id_Dorig)



	oForm = RunFediDoc(This.Parent.Id_DoTes,,, Thisform, 'DOTes.Id_DOTes = ' + Format4Spt(This.Parent.Id_DoTes), '', 0, This.Parent.Id_DoRig, 0)



	If Vartype(oForm) == 'O'

		oForm.CmdPGGenerale()

		oForm.PF.pgGenerale.PF.ActivePage = oForm.PF.pgGenerale.PF.pgRighe.PageOrder

		oForm.Show(1)

		ActivateWindow(Thisform)

	EndIf



EndIf



ENDPROC


*======================================================================

*** CLASS / OBJECT: TxtNumItem (BaseClass: container, Parent: detail.PF.pgFEPA.PFR.PGD.CntRead) ***
*** PROPERTIES ***
Top = 0

Left = 0

Width = 332

Height = 19

TabIndex = 1

Name = "TxtNumItem"

Label.Comment = "CD40AA88-0C4E-4F56-B491-D36006C7E9D3"

Label.FontUnderline = .T.

Label.Caption = "Rif. riga"

Label.Left = 0

Label.MousePointer = 15

Label.Top = 1

Label.ForeColor = 0,0,255

Label.Name = "Label"


*** METHODS ***
PROCEDURE Label.Click

Local oForm



If !IsEmpty(This.Parent.Id_Dotes) And !IsEmpty(This.Parent.Id_Dorig)



	oForm = RunFediDoc(This.Parent.Id_DoTes,,, Thisform, 'DOTes.Id_DOTes = ' + Format4Spt(This.Parent.Id_DoTes), '', 0, This.Parent.Id_DoRig, 0)



	If Vartype(oForm) == 'O'

		oForm.CmdPGGenerale()

		oForm.PF.pgGenerale.PF.ActivePage = oForm.PF.pgGenerale.PF.pgRighe.PageOrder

		oForm.Show(1)

		ActivateWindow(Thisform)

	EndIf



EndIf



ENDPROC


*======================================================================

*** CLASS / OBJECT: txtCommessa (BaseClass: container, Parent: detail.PF.pgFEPA.PFR.PGO.CntRead) ***
*** PROPERTIES ***
Anchor = 10

Top = 98

Left = 0

Width = 472

Height = 19

TabIndex = 5

ZOrderSet = 10

Name = "txtCommessa"

Label.Comment = "F9C67A6B-71B2-4D83-98B2-32426FEA8F9C"

Label.Caption = "Commessa"

Label.Left = 0

Label.Top = 1

Label.Name = "Label"


*** METHODS ***
PROCEDURE Init

DoDefault()



This.Field.DisabledForeColor = oapp.colordecodedfield

ENDPROC


*======================================================================

*** CLASS / OBJECT: de (BaseClass: container, Parent: ) ***
*** PROPERTIES ***
Width = 231

Height = 374

dobitmask = (0x7FFFFFFF)

lockmode = (1+2+4+8)

Name = "de"


*** METHODS ***
PROCEDURE orderbyinfogetset

LParameters lSet, cOrderBy



Local oUPref



oUPref = UP_GetUPref(UP_SCOPE_USER, JustStem(This.ClassLibrary) + '_' + ToHex(This.DOBitmask), This.Class + '_')

If lSet

	       oUPref.SetProperty('OrderByDE', cOrderBy)

Else

	Return oUPref.GetProperty('OrderByDE', cOrderBy)

EndIf

ENDPROC

PROCEDURE update_cursors

LParameters nMode



**	nMode	1 = Insert, 2 Delete, 3 Update



If nMode = 2

	Return DoDefault(nMode)

Else

	#Define DO_OPTION_NONE				0

	#Define DO_OPTION_SPESEINCASSO	1

	#Define DO_OPTION_SPESEBOLLI		2

	#Define DO_SKIP_INTRA				128



	Local nRet



	** Il par in + serve per evitare il check del movimento in edit

	nRet = xSqlExec('Exec asp_Do_Begin ' + Transform(DoTes.Id_DoTes) + ', 1')

	If nRet < 0

		Return nRet

	EndIf

	

	nRet = DoDefault(nMode)

	Iif(nRet >= 0 And nMode = 3, ThisForm.LinkOnDemand(), .T.)		&& Update



	If nRet >= 0

		Local oChkSpeseBolli

		oChkSpeseBolli = 	ThisForm.PF.PGGenerale.PF.PgPiede.Cnt.CntFattura.ChkSpeseBolli



		** Eventualmente per forzare il ricalcolo del bollo.

		** Attualmente il flag bollil in modifica non viene più proposto se il doc è contab

		

		**	If nMode = 3 And (oChkSpeseBolli.Visible And !oChkSpeseBolli.Value)

		**		Debugout xSQLExec2Var(Textmerge('Select TotEsenteE From DoTotali Where Id_DOtes = <<Dotes.Id_DoTes>>'))

		**	EndIf



		nOptions       = 	Iif(oChkSpeseBolli.Visible And oChkSpeseBolli.Value, DO_OPTION_SPESEBOLLI, DO_OPTION_NONE) + ;

								Iif(nMode = 1 And !ThisForm.PF.pgGenerale.txtCd_CF.Field.FKRecord.Intra, DO_SKIP_INTRA, 0)



		** Se sono in modifica e voglio gestire le spese bolli auto devo dire al server di rigenerare i dati iva perché il codice di rigenerazione è in ASP_DO_DOIVA_INS

		** Non mi posso fidare delle rilevazioni nei TRG

		Iif(nMode = 3 And Bitand(nOptions, DO_OPTION_SPESEBOLLI) != 0, xSQLExec("UPDATE DoTes SET Reserved_1 = STUFF(Reserved_1, 1, 1, 'R') WHERE Id_DoTes = " + Tran(DoTes.Id_DoTes)), .T.)

		nRet           = xSqlExec("Exec asp_Do_End " + Transform(DoTes.Id_DoTes) + ', ' + Transform(nOptions))

	EndIf



	Return nRet



EndIf





ENDPROC

PROCEDURE update_completed

Lparameters nMode, lCommitted



** No Delete

Iif(lCommitted And nMode != 2, Thisform.LinkManager(), .T.)

Return DoDefault(nMode, lCommitted)



ENDPROC

PROCEDURE Init

Lparameters nHostedBy



If PemStatus(Thisform, 'Parameters', 5) ; && da Main non esiste Parameters

	And !(Thisform.Parameters.ParamCount = 1 And Type('Thisform.Parameters.Param1') = 'O' And PemStatus(Thisform.Parameters.Param1, 'FTE_Import', 5)) && non richiamata dalla Cmd_FTE_Import

	

	This.DoBitMask = Evl(Thisform.Parameters.ParamGet(1, This.DoBitMask), This.DoBitMask) && Posso 'sovrascrivere' This.DoBitMask passandolo come 1^ parametro

EndIf 



Return DoDefault(nHostedBy)





ENDPROC

PROCEDURE userprefgetkey

RETURN Juststem(This.ClassLibrary) + '_' + ToHex(This.DOBitmask)



ENDPROC

PROCEDURE opencursors

Lparameters lOnlyMainCursor, cInitialWhere, cFixedWhere, cOrderBy



If This.DoBitMask != TD_TUTTO

	cFixedWhere = '(DoTes.DoBitMask & ' + ToHex(This.DoBitMask) + ' != 0)' +  Iif(Empty(cFixedWhere), '', ' And ' + cFixedWhere)

EndIf



Return DoDefault(lOnlyMainCursor, cInitialWhere, cFixedWhere, cOrderBy)





ENDPROC


*======================================================================

*** CLASS / OBJECT: DoTes (BaseClass: textbox, Parent: de) ***
*** PROPERTIES ***
Comment = "84462557-146B-4980-B419-FA68D6860905"

TabIndex = 1

wheretype = 1

orderby = DOTes.DataDoc Desc, DOTes.NumeroDoc Desc

name4progbar = Testa

Name = "DoTes"


*** METHODS ***
PROCEDURE update

LParameters nRequeryType, lForceAllModified, nWhereType, nUDIType



If !IsNull(DoTes.Cd_CF_Fatt) And Empty(SubStr(DoTes.Cd_CF_Fatt, 2))

	Replace Cd_CF_Fatt With Null In DoTes

EndIf



If This.IsRecChanged() = 2

	** Cancellazione gestisco la cancellazione in modo particolare.

	If xSqlExec('Exec asp_Do_Del ' + Transform(DoTes.Id_DOTes)) => 0

		This.TableUpdate()

		Return +2

	Else

		This.TableRevert()

		Return -2

	EndIf

Else

	Return DoDefault(nRequeryType, lForceAllModified, nWhereType, nUDIType)

EndIf







ENDPROC

PROCEDURE initcolsinfo

DoDefault()



This.aColsInfo('Cd_CF_R'				 ).RemoteFullName = 'IsNull(DoTes.Cd_CF_Auto, DoTes.Cd_CF)'	

This.aColsInfo('CFDesc_R'				 ).RemoteFullName = 'IsNull(CFA.Descrizione, CF.Descrizione)'	



This.aColsInfo('CFDesc'              ).RemoteFullName = 'CF.Descrizione'

This.aColsInfo('CNDesc'              ).RemoteFullName = 'CN.Descrizione'	

This.aColsInfo('PGDesc'              ).RemoteFullName = 'PG.Descrizione'	

This.aColsInfo('Agente_1_Descrizione').RemoteFullName = 'Ag_1.Descrizione'	

This.aColsInfo('Agente_2_Descrizione').RemoteFullName = 'Ag_2.Descrizione'	

This.aColsInfo('TotDocumentoV'       ).RemoteFullName = 'DoTotali.TotDocumentoV'	

This.aColsInfo('Reserved_1'          ).IsUpdatable	   = .F.	



This.aColsInfo('OC_Scaduto').RemoteFullName = 'DOTes.OC_Scaduto'

This.aColsInfo('OC_Scaduto'          ).IsUpdatable	   = .F.



This.aColsInfo('StatoFTE'    		    ).RemoteFullName = 'FTE_WorkFlow.Bar_Caption'	

This.aColsInfo('StatoFTE'         	 ).IsUpdatable	   = .F.	



This.aColsInfo('FactoringStatus'     ).RemoteFullName = 'FP.Status'

This.aColsInfo('FactoringStatus'     ).IsUpdatable	   = .F.	

This.aColsInfo('FactoringNumero'     ).IsUpdatable	   = .F.	

This.aColsInfo('FactoringLink'     	 ).IsUpdatable	   = .F.	





ENDPROC

PROCEDURE Init

Local cCIP_Peppol, cTIP_Peppol

Local cCIP_Factor, cTIP_Factor

Local cWhereParcella 



** Colonne usate da PEPPOL (le valorizzo solo se c'è il modulo attivo)

If oApp.LicInfo.Peppol = 0 And !oApp.LicInfo.PeppolPas

	cCIP_Peppol = ', PeppolOrder = 0, PeppolDespatch = 0 '

	cTIP_Peppol = ''

Else

	Text To cCIP_Peppol NoShow

		,PeppolOrder    = Case 	When CF.Cliente = 1 And DoTes.TipoDocumento = 'O' 																		  		 And (CF.PartitaIVA Is Not Null Or CF.CodiceFiscale Is Not Null) And D.Id_DmsDocument Is Not Null 	Then 1 

																																																								  																							Else 0 End



		,PeppolDespatch = Case 	When CF.Cliente = 1 And DoTes.TipoDocumento = 'B' And DoTes.Esecutivo = 1 And CF.Peppol_EndPoint Is Not Null And PR.Cd_Regione = 'EMR' And (CF.PartitaIVA Is Not Null Or CF.CodiceFiscale Is Not Null) And D.Id_DmsDocument Is Not Null 	Then 2

										When CF.Cliente = 1 And DoTes.TipoDocumento = 'B' And DoTes.Esecutivo = 1 And CF.Peppol_EndPoint Is Not Null And PR.Cd_Regione = 'EMR' And (CF.PartitaIVA Is Not Null Or CF.CodiceFiscale Is Not Null) And D.Id_DmsDocument Is     Null 	Then 1

																																																 								  																																Else 0 End

	EndText 

	Text To cTIP_Peppol NoShow

	   Left Outer Join DmsDocument D On D.EntityTable = 'DOTES' And D.EntityID = DoTes.Id_DOTes And D.Tag = Case When Left(DOTes.Cd_CF, 1) = 'C' And DoTes.TipoDocumento = 'O' Then 'OPO' When  Left(DOTes.Cd_CF, 1) = 'C' And DoTes.TipoDocumento = 'B' Then 'OPD' End	   

	EndText 

EndIf 



** Colonne usate da Factoring (le valorizzo solo se c'è il modulo attivo)

If !oApp.LicInfo.DO_Factoring Or !oApp.oUser.AccessFactoring &&Or !InList(Thisform.DOBitMask, 0x0000000008, 0x0000000010)

	cCIP_Factor = ', FactoringId = Null, FactoringNumero = Null, FactoringLink = Null, FactoringStatus = Null '

	cTIP_Factor = ''

Else



	Text To cCIP_Factor NoShow

		, FactoringId		= FP.Id_FactoringProject

		, FactoringNumero = FP.Numero

		, FactoringLink 	= FP.Link

		, FactoringStatus = Case FP.Status 	When 'CONF' Then 'Da Confermare'

														When 'ISTR' Then 'In istruttoria'

														When 'INER' Then 'In attesa erogazione'

														When 'EROG' Then 'Credito erogato'

														When 'AREN' Then 'In sospeso'

														Else Null End

	EndText 

	cTIP_Factor = "Left Join FactoringProject FP On DoTes.Id_FactoringProject = FP.Id_FactoringProject"



EndIf 



cWhereParcella = ' And DOAA.Cd_ParcT Is Null '



Text To This.Stmt Textmerge NoShow



	Select 

		DoTes.*,

		DoTes.OC_Scaduto,

				

		DOAA.AutoArchivia,

		DOAA.DIEnabled,

		DOAA.DIExecutive,

		DOAA.DISave,

		DOAA.FTE_AutoTipo,

	

		DoTotali.AbbuonoE,

		DoTotali.AccontoE,

		DoTotali.TotImponibileV,

		DoTotali.TotImponibileE,

		DoTotali.TotImpostaV,

		DoTotali.TotImpostaE,

		DoTotali.TotImpostaRCV,

		DoTotali.TotImpostaRCE,

		DoTotali.TotDocumentoV,

		DoTotali.TotDocumentoE,

		DoTotali.TotMerceLordoV,

		DoTotali.TotMerceLordoE,

		DoTotali.TotMerceNettoV,

		DoTotali.TotMerceNettoE,

		DoTotali.TotEsenteV,

		DoTotali.TotEsenteE,

		DoTotali.TotSpese_TV,

		DoTotali.TotSpese_TE,

		DoTotali.TotSpese_NV,

		DoTotali.TotSpese_NE,

		DoTotali.TotSpese_MV,

		DoTotali.TotSpese_ME,

		DoTotali.TotSpese_BV,

		DoTotali.TotSpese_BE,

		DoTotali.TotSpese_AV,

		DoTotali.TotSpese_AE,

		DoTotali.TotSpese_VV,

		DoTotali.TotSpese_VE,

		DoTotali.TotSpese_ZV,

		DoTotali.TotSpese_ZE,

		DoTotali.TotSpeseV,

		DoTotali.TotSpeseE,

		DoTotali.TotScontoV,

		DoTotali.TotScontoE,

		DoTotali.TotOmaggio_MV,

		DoTotali.TotOmaggio_ME,

		DoTotali.TotOmaggio_IV,

		DoTotali.TotOmaggio_IE,

		DoTotali.TotaPagareV,

		DoTotali.TotaPagareE,

		DoTotali.TotProvvigione_1V,

		DoTotali.TotProvvigione_1E,

		DoTotali.TotProvvigione_2V,

		DoTotali.TotProvvigione_2E,

		DoTotali.RA_ImportoV,

		DoTotali.RA_ImportoE,

		DoTotali.Arrotondamento,



		VL.PicSep,

		CF.Descrizione   	As CFDesc,

		CF.EntePubblico,

		CF.CodiceIPA,

		CF.CodiceFPR,

		CN.Descrizione   	As CNDesc,

		CN.FatturaElettronica,

		PG.Descrizione   	As PGDesc, 

		Ag_1.Descrizione 	As Agente_1_Descrizione,

		Ag_2.Descrizione 	As Agente_2_Descrizione,

		

		Cd_CF_R	= IsNull(DoTes.Cd_CF_Auto, DoTes.Cd_CF),

		CFDesc_R	= IsNull(CFA.Descrizione, CF.Descrizione),

		

		

		StatoFTE = FTE_WorkFlow.Bar_Caption,



		FTE_IsInDMS			= Cast(Case When 	Exists(Select * From DmsDocument Where EntityTable = 'DOTes'  And EntityId = DoTes.Id_DoTes   																And Tag = 'FTE') Or

													  	Exists(Select * From DmsDocument Where EntityTable = 'CGMovT' And EntityId = (Select Id_CGMovT From CGMovT Where Id_DoTes = DoTes.Id_DoTes) 	And Tag = 'FTE')											Then 1 Else 0 End As Bit),



		FTE_CanModify		= Cast(Case When  Exists(Select * From DmsDocument Where EntityTable = 'DOTes'  And EntityId = DoTes.Id_DoTes   And Tag = 'Fte' Collate Latin1_General_CS_AS 	And Id_ArkManager Is Null And Id_PdV Is Null) 	Then 1 Else 0 End As Bit)



		<<cCIP_Peppol>>

		

		<<cCIP_Factor>>



		/*CIP*/

		

	From 

		(Select 

			<<This.ColumnsList('DoTes', 'Attributi') && escludo Attributi altrimenti viene trasformata in varchar(max) >>, 

			DoTes.Attributi,

			Convert(Bit, Case When DOTes.DOBitMask & 0x00002002 != 0 And DoTes.RigheEvadibili > 0 And DoTes.DataConsegna < dbo.afn_dt_GetDate() Then 1 Else 0 End) As OC_Scaduto 

		From 

			DoTes

			Join orsDO(<<oApp.oUser.Id_Operatore>>) U On U.Cd_DO	= DoTes.Cd_DO

		) As DoTes



		Left Outer Join CF						On DoTes.Cd_CF 		= CF.Cd_CF

		Left Outer Join CF				CFA	On DoTes.Cd_CF_Auto 	= CFA.Cd_CF

		Left Outer Join Provincia 		PR		On PR.Cd_Provincia 	= CF.Cd_Provincia And PR.Cd_Nazione = 'IT'

	   Left Outer Join VL						On DoTes.Cd_VL		   = VL.Cd_VL

	   Left Outer Join CN						On DoTes.Cd_CN		   = CN.Cd_CN

	   Left Outer Join DoTotali				On DoTes.Id_DOTes	   = DoTotali.Id_DOTes

	   Left Outer Join PG						On DoTes.Cd_PG		   = PG.Cd_PG	

	   Left Outer Join Agente Ag_1			On DoTes.Cd_Agente_1 = Ag_1.Cd_Agente	

	   Left Outer Join Agente Ag_2			On DoTes.Cd_Agente_2 = Ag_2.Cd_Agente	

	   Left Outer Join DO				DOAA	On DoTes.Cd_DO		   = DOAA.Cd_DO

	   Left Outer Join FTE_WorkFlow  		On DoTes.FTE_Status	= FTE_WorkFlow.FTE_Status

	   

		<<cTIP_Peppol>>



		<<cTIP_Factor>>



		/*TIP*/

		

	<WHERE> <<cWhereParcella>>

	<ORDERBY>

	

EndText



Return DoDefault()



*			orsDO(<<oApp.oUser.Id_Operatore>>) U 

*			Join DoTes On U.Cd_DO = DoTes.Cd_DO





ENDPROC


*======================================================================

*** CLASS / OBJECT: DORig (BaseClass: textbox, Parent: de) ***
*** PROPERTIES ***
Comment = "A55D248B-8A34-4B2E-AD03-3966AE1C505A"

Left = 14

TabIndex = 2

Top = 100

name4progbar = Righe

orderby = DORig.Riga

Name = "DORig"


*** METHODS ***
PROCEDURE update

Lparameters nRequeryType, lForceAllModified, nWhereType, nUDIType



Local nId, nRet, nCurRec, nOldWA, cFilterSaved, nId_DoRig, nId_DoDb



nRet = 0

If !Between(DoRig.Omaggio, 1, 3)

	Replace DoRig.Omaggio With 1 In DORig

Endif



If nRet >= 0

	nCurRec = Recno('DORig')

	If Dotes.Contabile

		Replace QtaEvadibile With 0 In Dorig

	Endif



	** #DICHINT#

	If Nvl(DoRig.Id_Dorig, 0) <= 0 Or ;

	 	!SafeCompare(Oldval('Cd_Aliquota_e', 'dorig'), Dorig.Cd_Aliquota_e) Or ;

		!SafeCompare(Oldval('DoIntento', 	 'dorig'), Dorig.DoIntento)

	

		Replace DoIntento 	With Iif(IsEmpty(Dorig.Cd_Aliquota_e), Null, Dorig.DoIntento), DoIntentoFix With !Dotes.DISave

		Replace ExtraInfo 	With Thisform.oDoIntento.ToExtraInfo(Dorig.ExtraInfo, Dorig.DoIntento)



	EndIf

	

	nRet = DoDefault(2, lForceAllModified, nWhereType, nUDIType)



	nOldWA = Select(0)



	Select DoRigPackList

	cFilterSaved = Set("Filter")

	Set Filter To

	If nCurRec < 0

		Replace Id_DoRig With DoRig.Id_DORig For Id_DoRig = nCurRec

	Endif

	Set Filter To &cFilterSaved



	If Used('ADLink_DORig')

		Select ADLink_DORig

		If nCurRec < 0

			Replace Id_DoRig With DoRig.Id_DORig For Id_DoRig = nCurRec

		Endif

	EndIf

	

	Select (nOldWA)



Endif



Return nRet



ENDPROC

PROCEDURE update_records

Local nOldWA, nRet, cOldFilter



nOldWA = Select (0)

Thisform.RinumeraRighe('DoRig')

Delete For Empty(Cd_AR) And Empty(Descrizione)

Replace ID_DoTes With DoTes.ID_DoTes For !(DoRig.ID_DoTes == DoTes.ID_DoTes)



nRet = DoDefault()

Select (nOldWA)



Return nRet



ENDPROC

PROCEDURE Init

** NB: il campo NoteRighe deve essere ancora NULLable ma si deve evitare di avere i valori NULL per via del problema VFP delle editbox poste su Grid (digitazione primo carattere)



Text To This.Stmt TEXTMERGE NoShow

	Select 

		<<This.ColumnsList('DoRig', 'NoteRiga,Matricole')>>

		, NoteRiga						= Convert(Text,  IsNull(DoRig.NoteRiga, ''))

		, Matricole						= Convert(VarChar(Max), DoRig.Matricole	 )

		, QtaEvasa_InOrigine			= DoRig.QtaEvasa

		, FattoreToUM1_Prelevato	= D2.FattoreToUm1

		, DocEvaso_Cd_AR				= D2.Cd_AR

		, DocEvaso_FattoreToUM1		= ISNULL(D2.FattoreToUm1, 1)

		, DocEvaso_Riga				= D2.Riga

		, DocEvaso_Cd_DO				= D2.Cd_DO

		, DocEvaso_NumeroDoc			= D2.NumeroDoc

		, DocEvaso_Qta					= D2.Qta

		, DocEvaso_QtaEvadibile		= ISNULL(D2.QtaEvadibile, 0)

		, DocEvaso_Cd_ArMisura 		= D2.Cd_ARMisura

		, DocEvaso_DataDoc			= D2.DataDoc

		, RR_Enabled					= IsNull(CGConto.RR_Enabled, 0)

		, SezioneBilancio				= IsNull(CGConto.SezioneBilancio, '')

		, ContoMerceSpesa				= IsNull(CGConto.ContoMerceSpesa, 0)

		, IvaMoss						= IsNull(Aliquota.IvaMoss, 0)

		, IvaSplit						= IsNull(Aliquota.IvaSplit, 0)

		, Iva_Split_Sep				= IsNull(Aliquota.Iva_Split_Sep, 0)

		, Cd_RC							= Aliquota.Cd_ReverseCharge

		, TipoFattura					= IsNull(RC.TipoFattura, 0)

		, DOIntento						= DORig.ExtraInfo.query('/ExtraInfo/rows[@Type="DOINTENTO"]')

		, DOIntentoCode				= Convert(Int, 0)

		/*CIP*/

	From DORig

		Left Join DORIG 			D2 On D2.Id_DORig = DORig.Id_DORIG_Evade

		Left Join CGConto  			On DORig.Cd_CGConto = CGConto.Cd_CGConto

		Left Join Aliquota			On DORig.Cd_Aliquota_r = Aliquota.Cd_Aliquota

		Left Join ReverseCharge	RC On DORIG.Cd_ReverseCharge = RC.Cd_ReverseCharge

		/*TIP*/

	<WHERE> 

	<ORDERBY>

EndText



Return DoDefault()



ENDPROC

PROCEDURE initcolsinfo

DoDefault()



This.aColsInfo('ScontoRiga'       ).IsNullable  = .F.

This.aColsInfo('ProvvigioneRiga_1').IsNullable  = .F.

This.aColsInfo('ProvvigioneRiga_2').IsNullable  = .F.

ENDPROC


*======================================================================

*** CLASS / OBJECT: DORigSpesa (BaseClass: textbox, Parent: de) ***
*** PROPERTIES ***
Comment = "F7AF32C3-C82A-40EC-B954-67750055F9C7"

Left = 14

TabIndex = 5

Top = 143

name4progbar = Righe Spesa

orderby = DorigSpesa.Riga

Name = "DORigSpesa"


*** METHODS ***
PROCEDURE requery

Lparameters cWhere, cOrderBy

DODEFAULT(cWhere, cOrderBy)



REPLACE ALL RigaSpesa_Evasa WITH ;

	'Documento               : ' + DocEvaso_Cd_DO + ' ' + Alltrim(DocEvaso_NumeroDoc) + ' del ' + DTOC(DocEvaso_DataDoc) + CRLF + ;

	'Riga                    : ' + Transform(DocEvaso_Riga) + CRLF +;

	'Importo                 : ' + Transform(DocEvaso_ImportoV, PicSep) + ' ' + Cd_VL +  CRLF +;

	'Importo evadibile       : ' + Transform(DocEvaso_ImportoEvadibileV + ImportoEvasoV_InOrigine, PicSep) + ' ' + Transform(Cd_VL) + CRLF +;

	'Importo evaso in origine: ' + Transform(ImportoEvasoV_InOrigine, PicSep) + ' ' + Transform(Cd_VL) ;

	FOR !ISNULL(DocEvaso_Cd_DO) IN DoRigSpesa

TABLEUPDATE(2, .t.,  'DoRigSpesa')	

GO TOP  IN DoRigSpesa

	

 

ENDPROC

PROCEDURE update_records

THISFORM.RinumeraRighe('DoRigSpesa')



Delete For Empty(TipoRigaSpesa) OR (Empty(ImportoV) And Empty(Perc)) OR Empty(Cd_CGConto)

Replace ID_DoTes With DoTes.ID_DoTes FOR !(DoRigSpesa.ID_DoTes = DoTes.ID_DoTes)



** La % di spesa la accetto soltanto sul trasporto in accordo con il check sul db

Replace Perc With 0 For TipoRigaSpesa != 'T' And Perc != 0



RETURN DODEFAULT()

ENDPROC

PROCEDURE initcolsinfo

DoDefault()



THIS.aColsInfo('Reserved_1').IsUpdatable	= .F.



		

ENDPROC

PROCEDURE Init

TEXT TO THIS.Stmt TEXTMERGE NOSHOW PRETEXT 7

	SELECT

		<<This.ColumnsList('DoRigSpesa')>>

		, RigaSpesa_Evasa					= Convert(Varchar(500), '')

		, DocEvaso_Cd_DO					= DoTes.Cd_Do

		, DocEvaso_DataDoc				= DoTes.DataDoc

		, DocEvaso_NumeroDoc				= DoTes.NumeroDoc

		, DocEvaso_RIga					= DoRigSpesa_Evasa.Riga

		, DocEvaso_ImportoV				= DoRigSpesa_Evasa.ImportoV

		, DocEvaso_ImportoEvadibileV	= DoRigSpesa_Evasa.ImportoEvadibileV

		, ImportoEvasoV_InOrigine		= DoRigSpesa.ImportoEvasoV

		, PicSep								= Right(VL.PicSep,10)

		, IvaMoss							= IsNull(Aliquota.IvaMoss, 0)

		, IvaSplit							= IsNull(Aliquota.IvaSplit, 0)

		, Iva_Split_Sep					= IsNull(Aliquota.Iva_Split_Sep, 0)

		, Cd_RC								= Aliquota.Cd_ReverseCharge

		, TipoFattura						= IsNull(RC.TipoFattura, 0)

		, DOIntento							= DORigSpesa.Extrainfo.query('/ExtraInfo/rows[@Type="DOINTENTO"]')

		, DOIntentoCode					= Convert(Int, 0)

		/*CIP*/

	FROM DoRigSpesa

		/*TIP*/ 

		Left Join DoRigSpesa AS DoRigSpesa_Evasa ON DoRigSpesa.Id_DorigSpesa_Evade = DoRigSpesa_Evasa.Id_DorigSpesa

		Left Join DoTes 		ON DoRigSpesa_Evasa.Id_DoTes 	= DoTes.Id_DoTes

		Left Join VL    		ON DoRigSpesa_Evasa.Cd_VL 		= VL.Cd_VL

		Left Join Aliquota	On DORigSpesa.Cd_Aliquota_r 	= Aliquota.Cd_Aliquota

		Left Join ReverseCharge	RC On DoRigSpesa.Cd_ReverseCharge = RC.Cd_ReverseCharge

	<WHERE> <ORDERBY>	

ENDTEXT



Return DODEFAULT()





ENDPROC

PROCEDURE update

Lparameters nRequeryType, lForceAllModified, nWhereType, nUDIType



** #DICHINT#

If Nvl(DoRigSpesa.Id_DorigSpesa, 0) <= 0 Or ;

	!SafeCompare(Oldval('Cd_Aliquota_e', 'dorigspesa'), Dorigspesa.Cd_Aliquota_e) Or ;

	!SafeCompare(Oldval('DoIntento', 	 'dorigspesa'), Dorigspesa.DoIntento)



	Replace DoIntento With Iif(IsEmpty(DorigSpesa.Cd_Aliquota_e), Null, DorigSpesa.DoIntento), DoIntentoFix With !Dotes.DISave

	Replace ExtraInfo With Thisform.oDoIntento.ToExtraInfo(DorigSpesa.ExtraInfo, DorigSpesa.DoIntento)



EndIf

	

nRet = DoDefault(nRequeryType, lForceAllModified, nWhereType, nUDIType)



Return nRet



ENDPROC


*======================================================================

*** CLASS / OBJECT: Impostazione (BaseClass: textbox, Parent: de) ***
*** PROPERTIES ***
Comment = "83247579-4CE1-4386-AFB1-C32F29582A63"

Left = 4

TabIndex = 10

Top = 217

Name = "Impostazione"


*** METHODS ***
PROCEDURE Init

Lparameters cStmt, cWhere, cOrderBy



cWhere = "I.Cd_Impostazione = 'DEFAULT_RIGHE_DOC'"

			

Text To cStmt NoShow

	Select 

		I.Cd_CGConto_1  	AS Cd_CGConto_Acq,

		I.Cd_CGConto_2  	AS Cd_CGConto_Ven,

		I.Cd_Aliquota_1 	AS Cd_Aliquota_Acq,

		I.Cd_Aliquota_2 	AS Cd_Aliquota_Ven,

		P.CGRACondominio,

		P.Imp_DOEsente_ApplicaNC,

		P.Imp_DOEsente_Limite,

		P.Imp_DOEsente_Spese,

		P.CGCorrispondenzaIvaMerce

		/*CIP*/

	FROM 

		Impostazione I,

		Preferenza   P

		/*TIP*/

	<WHERE>

	<ORDERBY>

EndText



DoDefault(cStmt, cWhere, cOrderBy)





ENDPROC


*======================================================================

*** CLASS / OBJECT: DoDB (BaseClass: textbox, Parent: de) ***
*** PROPERTIES ***
Comment = "555E9F57-2D3F-46A6-8D4B-A4811D4152F9"

Left = 14

TabIndex = 6

Top = 28

requerytype = 2

name4progbar = Distinte

Name = "DoDB"


*** METHODS ***
PROCEDURE Init

Text To This.Stmt TextMerge NoShow

	Select 

		<<This.ColumnsList('DoDB')>>

		/*CIP*/

	From 

		DoDb

		/*TIP*/

	<WHERE> 

	<ORDERBY>

EndText



DoDefault()

		

ENDPROC

PROCEDURE update

Lparameters nRequeryType, lForceAllModified, nWhereType, nUDIType



Local nId_DoDB_New, nId_DoDB_Old, nRet



nId_DoDB_Old = DoDB.Id_DoDB

nRet = DoDefault(nRequeryType, lForceAllModified, nWhereType, nUDIType)

nId_DoDB_New = DoDB.Id_DoDB

	

** Se ci sono state modifiche alla distinta custom  forzo l'aggiornamento dei movimenti di magazzino;

** a causa dell'ottimizzazione presente nel trigger di DoRig che interrompe il trigger qualora ci sia

** il solo campo  Reserved_1  modificato è bene aggiornare anche il campo Id_DoDB così sono sicuro di

** generare i movimenti di magazzino anche se nessun altro dato di riga risulta modificato



If nRet > 0

	Replace																												;

		Id_DoDB 	  With DoRig.Id_DoDB																				;

		Reserved_1 With Chrtran(Stuff(Padr(Nvl(Reserved_1, ''),10,'0'), 3, 1, 'U'), ' ', '0')	;

   For DoRig.Id_DoDB = DoDB.Id_DoDB In DoRig

EndIf



If nId_DoDB_Old != DoDB.Id_DoDB

	Replace Id_DoDB With nId_DoDB_New For Id_DoDB = nId_DoDB_Old In DoDBAttivita

	Replace Id_DoDB With nId_DoDB_New For Id_DoDB = nId_DoDB_Old In DoRig

EndIf 



Return nRet



ENDPROC

PROCEDURE requery

Lparameters cWhere, cOrderBy, lAppendMode



Local nRet, nCount, oRec, nRec



If !lAppendMode

	** modalità di requery standard: viene costruito un nuovo cursore

	nRet = DoDefault(cWhere, cOrderBy)

	This.MakeIndex('Id_DoDB', 'Id_1')

	Set Order To 0 	

Else

	** modalità di requery avanzata (cWhere lavora su Id_DoDB): se la distinta relativa a Id_DoDB

	** non è già presente nel cursore, questa viene scaricata e appesa

	** al cursore

	Select DoDB

	nRec = Recno()

	Count For &cWhere To nCount

	Locate Record nRec 

	If nCount == 0

	   xSqlExec(This.BuildRequeryStmt(cWhere), 'mp_4_Req_Children')

	   Select mp_4_Req_Children

	   Scan

		   Select mp_4_Req_Children	   

			Scatter Memo Name oRec

			Select DoDB

			Append Blank

			Gather Name oRec Memo

			TableUpdate(0, .F., 'DoDB')

	   EndScan

   	Use In mp_4_Req_Children

	EndIf

EndIf

Return nRet



ENDPROC


*======================================================================

*** CLASS / OBJECT: DoDBAttivita (BaseClass: textbox, Parent: de) ***
*** PROPERTIES ***
Comment = "1C623763-753C-414A-95E7-6F62DF9879AB"

Left = 33

TabIndex = 7

Top = 48

requerytype = 2

name4progbar = Attività Distinte

Name = "DoDBAttivita"


*** METHODS ***
PROCEDURE update_records

** Esistendo una relazione tra gli Id dei record (parent/child) questi devono

** essere elaboarati dal cursore nell'ordine corretto; questo viene garantito

** attivando l'ordine corretto 

** Nella fattispecie, elaborando una struttura ad albero, le modifiche 

** (aggiornamento o cancellazione) devono essere riportate a partire dai livelli 

** più profondi (foglie)

** In tal modo si evita di tentare di aggiornare un nodo precedentemente cancellato 

** a causa delle regole di integrità referenziale presenti nel database.



Set Order To Attivita

Return DoDefault()

ENDPROC

PROCEDURE update

Lparameters nRequeryType, lForceAllModified, nWhereType, nUDIType



Local nRec, nId_DoDBAttivita_New, nId_DoDBAttivita_Old, nRet



nId_DoDBAttivita_Old = DoDBAttivita.Id_DoDBAttivita

nRet = DoDefault(nRequeryType, lForceAllModified, nWhereType, nUDIType)

nId_DoDBAttivita_New = DoDBAttivita.Id_DoDBAttivita

	

** Se ci sono state modifiche alla distinta custom  forzo l'aggiornamento dei movimenti di magazzino;

** a causa dell'ottimizzazione presente nel trigger di DoRig che interrompe il trigger qualora ci sia

** il solo campo  Reserved_1  modificato è bene aggiornare anche il campo Id_DoDB così sono sicuro di

** generare i movimenti di magazzino anche se nessun altro dato di riga risulta modificato



If nRet > 0

	Replace																												;

		Id_DoDB 	  With DoRig.Id_DoDB																				;

		Reserved_1 With Chrtran(Stuff(Padr(Nvl(Reserved_1, ''),10,'0'), 3, 1, 'U'), ' ', '0')	;

   For DoRig.Id_DoDB = DoDB.Id_DoDB In DoRig

EndIf



If nId_DoDBAttivita_Old != DoDBAttivita.Id_DoDBAttivita

	Replace Id_DoDBAttivita		   With nId_DoDBAttivita_New For Id_DoDBAttivita = nId_DoDBAttivita_Old In DoDBMateriale

	nRec = Recno()	

	Replace Id_DoDBAttivita_Next	With nId_DoDBAttivita_New For Id_DoDBAttivita_Next = nId_DoDBAttivita_Old

	Locate Record nRec

EndIf 



Return nRet





ENDPROC

PROCEDURE Init

Text To This.Stmt TextMerge NoShow

	Select 

		<<This.Columnslist('DoDBAttivita')>>, 

		PrRisorsa.Gruppo,

		PrRisorsa.Esterno,		

		IsNull(PRRisorsa.CostoOrario, Convert(Numeric(18,2), 0))	As CostoOrario, 

		Convert(Bit, 1)														As IsValid

		/*CIP*/

	From 

		DoDbAttivita

		/*TIP*/

	Left Outer Join PRRisorsa On DoDBAttivita.Cd_PRRisorsa = PRRisorsa.Cd_PRRisorsa

	<WHERE> 

	<ORDERBY>

EndText



DoDefault()

		

		

ENDPROC

PROCEDURE requery

Lparameters cWhere, cOrderBy, lAppendMode



Local nRet, nCount, oRec, nRec



If !lAppendMode

	** modalità di requery standard: viene costruito un nuovo cursore

	nRet = DoDefault(cWhere, cOrderBy)

	This.MakeIndex('Id_DoDb'								 , 'Id_1'    )	

	This.MakeIndex('Id_DoDbAttivita'						 , 'Id_2'    )

	This.MakeIndex('BinToC(Id_DoDb) + BinToC(Sequenza)', 'Attivita')		

	Set Order To 0 		

Else

	** modalità di requery avanzata (cWhere lavora su Id_DoDB): se le attività relative a Id_DoDB

	** non sono già presenti nel cursore, queste vengono scaricate e appese al cursore

	Select DoDBAttivita

	nRec = Recno()

	Count For &cWhere To nCount

	Locate Record nRec 

	If nCount == 0

	   xSqlExec(This.BuildRequeryStmt(cWhere), 'mp_4_Req_Children')

	   Select mp_4_Req_Children

	   Scan

		   Select mp_4_Req_Children	   

			Scatter Memo Name oRec

			Select DoDBAttivita

			Append Blank

			Gather Name oRec Memo

			TableUpdate(0, .F., 'DoDBAttivita')

	   EndScan

   	Use In mp_4_Req_Children

	EndIf

EndIf

Return nRet



ENDPROC


*======================================================================

*** CLASS / OBJECT: DoDBMateriale (BaseClass: textbox, Parent: de) ***
*** PROPERTIES ***
Comment = "3029C716-427F-47A3-B91F-72D717D84438"

Left = 51

TabIndex = 8

Top = 68

name4progbar = Materiali Distinte

Name = "DoDBMateriale"


*** METHODS ***
PROCEDURE requery

Lparameters cWhere, cOrderBy, lAppendMode



Local nRet, nCount, oRec, nRec



If !lAppendMode

	** modalità di requery standard: viene costruito un nuovo cursore

	nRet = DoDefault(cWhere, cOrderBy)

	This.MakeIndex('Id_DoDb'													       , 'Id_1'     )

	This.MakeIndex('Id_DoDbAttivita'											       , 'Id_2'     )		

	This.MakeIndex('Id_DoDbMateriale'											    , 'Id_3'     )			

	This.MakeIndex('BinToC(Id_DoDbAttivita) + BinToC(0x7FFFFFFF-Sequenza)', 'Materiale')		

	Set Order To 0 		

Else

	** modalità di requery avanzata (cWhere lavora su Id_DoDB): se i materiali relativi a Id_DoDB

	** non sono già presenti nel cursore, questi vengono scaricati e appesi al cursore

	Select DoDBMateriale

	nRec = Recno()

	Count For &cWhere To nCount

	Locate Record nRec 

	If nCount == 0

	   xSqlExec(This.BuildRequeryStmt(cWhere), 'mp_4_Req_Children')

	   Select mp_4_Req_Children

	   Scan

		   Select mp_4_Req_Children	   

			Scatter Memo Name oRec

			Select DoDBMateriale

			Append Blank

			Gather Name oRec Memo

			TableUpdate(0, .F., 'DoDBMateriale')

	   EndScan

   	Use In mp_4_Req_Children

	EndIf

EndIf

Return nRet





ENDPROC

PROCEDURE Init

Text To This.Stmt TextMerge NoShow

	Select

		DoDBAttivita.Id_DoDB,

		<<This.Columnslist('DoDbMateriale')>>,

		AR.Descrizione,

		AR.DBFantasma	As DBFantasma,

		Convert(Bit, Case When Exists(Select * From DB Where DB.Cd_AR = DoDbMateriale.Cd_AR) Then 1 Else 0 End) As SemiLavorato,

		Convert(Bit, 1)						 																							  As IsValid

		/*CIP*/

	From 

		DoDbMateriale

		/*TIP*/

	Inner Join DoDBAttivita On DoDBAttivita.Id_DoDBAttivita = DoDbMateriale.Id_DoDBAttivita	

	Inner Join AR           On                     AR.Cd_AR = DoDbMateriale.Cd_AR

	<WHERE> 

	<ORDERBY>

EndText



DoDefault()

		

ENDPROC

PROCEDURE update

Lparameters nRequeryType, lForceAllModified, nWhereType, nUDIType



Local nRet



nRet = DoDefault(nRequeryType, lForceAllModified, nWhereType, nUDIType)



** Se ci sono state modifiche alla distinta custom  forzo l'aggiornamento dei movimenti di magazzino;

** a causa dell'ottimizzazione presente nel trigger di DoRig che interrompe il trigger qualora ci sia

** il solo campo  Reserved_1  modificato è bene aggiornare anche il campo Id_DoDB così sono sicuro di

** generare i movimenti di magazzino anche se nessun altro dato di riga risulta modificato



If nRet > 0

	Replace																												;

		Id_DoDB 	  With DoRig.Id_DoDB																				;

		Reserved_1 With Chrtran(Stuff(Padr(Nvl(Reserved_1, ''),10,'0'), 3, 1, 'U'), ' ', '0')	;

   For DoRig.Id_DoDB = DoDB.Id_DoDB In DoRig

EndIf



Return nRet





ENDPROC


*======================================================================

*** CLASS / OBJECT: DOReport (BaseClass: textbox, Parent: de) ***
*** PROPERTIES ***
Comment = "1A0AA0EC-0494-43AB-8508-50589B7B956F"

Left = 14

TabIndex = 9

Top = 180

orderby = Riga

name4progbar = Report Stampa

Name = "DOReport"


*** METHODS ***
PROCEDURE requery

Lparameters cWhere, cOrderBy



If Used(This.Table)

	Tablerevert(.T., This.Table)

ENDIF

LOCAL xRet

xRet = DoDefault(cWhere, cOrderBy)

IF xRet AND RECCOUNT(This.Table) = 0

	APPEND BLANK IN (This.Table)

ENDIF

RETURN xRet

ENDPROC

PROCEDURE update_records

TABLEUPDATE(2, .T.)

RETURN 1

ENDPROC


*======================================================================

*** CLASS / OBJECT: DoRigPackList (BaseClass: textbox, Parent: de) ***
*** PROPERTIES ***
Comment = "4A316202-DEE5-442D-89CA-B87F7F320555"

Left = 33

TabIndex = 4

Top = 120

name4progbar = Packing List

Name = "DoRigPackList"


*** METHODS ***
PROCEDURE Init

Text To This.Stmt TextMerge NoShow



	Select 

		<<This.Columnslist('DoRigPackList')>>

		/*CIP*/

	From DoRigPackList

		Inner Join DoRig On DoRig.Id_DORig = DoRigPackList.Id_DORig

		/*TIP*/

	<WHERE> 

	<ORDERBY>

EndText



DoDefault()



ENDPROC

PROCEDURE update_records

LOCAL nRet, nOldWA

LOCAL cOldFilter



SELECT DoRigPackList

cOldFilter = SET('FILTER')

SET FILTER TO 

DELETE ALL FOR EMPTY(PackListRef) OR EMPTY(Id_DORig)

nRet = DODEFAULT()



SELECT DoRigPackList

SET FILTER TO &cOldFilter

GO TOP

RETURN nRet



ENDPROC


*======================================================================

*** CLASS / OBJECT: DoUiCfg (BaseClass: textbox, Parent: de) ***
*** PROPERTIES ***
Comment = "68BE235D-98D3-40C5-B765-CB81DC9662BA"

Left = 4

TabIndex = 10

Top = 240

Name = "DoUiCfg"


*** METHODS ***
PROCEDURE Init

Lparameters cStmt, cWhere, cOrderBy



xSqlExec("Select Name from sysobjects where name = 'DoUiCfg'", 'DoUiCfg_Exist')

If Eof('DoUiCfg_Exist')

	This.Stmt       = 'Select ' + ColumnsList('Agente') + ' From Agente <WHERE>'

	This.FixedWhere = '1=0'

Else

	This.Stmt       = 'Select ' + ColumnsList('DoUiCfg') + ' From DoUiCfg <WHERE>'

	This.FixedWhere = 'Id_DoUiCfg = ' + Tran(This.Parent.DoBitMask)

EndIf



DoDefault(cStmt, cWhere, cOrderBy)





ENDPROC


*======================================================================

*** CLASS / OBJECT: CGLiq (BaseClass: textbox, Parent: de) ***
*** PROPERTIES ***
Comment = "6B691099-22A3-4689-A81F-6692DCFC9FBC"

Left = 4

Top = 264

where = 1=1

Name = "CGLiq"


*** METHODS ***
PROCEDURE requery

Lparameters cWhere, cOrderBy



Local xRet



xRet = DoDefault(cWhere, cOrderBy)



This.MakeIndex('Cd_CgLiq')

This.MakeIndex('Prevalente')



AddProperty(This, 'Prevalente', xSQLExec2Obj('Select Top 1 * From CGLiq Where Prevalente = 1', .T.))



Return xRet



ENDPROC

PROCEDURE Init

Lparameters cStmt, cWhere, cOrderBy



Text To cStmt NoShow

	Select *

		/*CIP*/

	From CGLiq

		/*TIP*/

	<WHERE>

EndText



DoDefault(cStmt, cWhere, cOrderBy)



ENDPROC


*======================================================================

*** CLASS / OBJECT: ReverseCharge (BaseClass: textbox, Parent: de) ***
*** PROPERTIES ***
Comment = "6B691099-22A3-4689-A81F-6692DCFC9FBC"

Left = 4

Top = 284

where = 1=1

Name = "ReverseCharge"


*** METHODS ***
PROCEDURE requery

Lparameters cWhere, cOrderBy



Local xRet



xRet = DoDefault(cWhere, cOrderBy)



This.MakeIndex('Cd_ReverseCharge', 'Cd_RC')



Return xRet



ENDPROC

PROCEDURE Init

Lparameters cStmt, cWhere, cOrderBy



Text To cStmt NoShow

	Select *

		/*CIP*/

	From ReverseCharge

		/*TIP*/

	<WHERE>

EndText



DoDefault(cStmt, cWhere, cOrderBy)



ENDPROC


*======================================================================

*** CLASS / OBJECT: DoTesExtraInfo (BaseClass: textbox, Parent: de) ***
*** PROPERTIES ***
Height = 23

Left = 6

Top = 307

Width = 126

orderby = Isnull(T.sequenza, 999), Cd_DoTesExtraInfo

Name = "DoTesExtraInfo"


*** METHODS ***
PROCEDURE requery

Lparameters cWhere, cOrderBy



If !DoDefault(cWhere, cOrderBy)

	Return .F.

EndIf 



This.MakeIndex('Cd_DoTesExtraInfo', 'Cd')

Set Order To 







ENDPROC

PROCEDURE Init

Text To This.Stmt NoShow

	Select 

		DoTesExtraInfo.*

		/*CIP*/

	From DoTesExtraInfo

	Left Join ( Select xml.value('@extrainfo','varchar(22)') As Extrainfo,

							 xml.value('@sequenza', 'integer') 	   As Sequenza

					From ConfigData

					Cross Apply DataXML.nodes('rows/row') As Sequenza(xml)

					Where Ud_ConfigData = 'B6E1E9A7-D404-46F5-B89C-88C1A1222347'

					) T

						On DoTesExtraInfo.Cd_DoTesExtraInfo  = T.ExtraInfo

		/*TIP*/

	

	<WHERE> 

	<ORDERBY>

EndText



RETURN DoDefault()

		

ENDPROC


*======================================================================

*** CLASS / OBJECT: cntpeppol (BaseClass: container, Parent: ) ***
*** PROPERTIES ***
Width = 269

Height = 57

BorderWidth = 0

Name = "cntpeppol"


*** METHODS ***
PROCEDURE Refresh

This.btnUpload.Visible = !IsEmpty(DoTes.PeppolDespatch)

This.btnUpload.Caption = Iif(DoTes.PeppolDespatch = 2, 'Reinvia Doc. al Cliente', 'Invia Doc. al Cliente')

This.BtnState .Visible = !IsEmpty(DoTes.PeppolDespatch) And oApp.LicInfo.Peppol > 0

ENDPROC


*======================================================================

*** CLASS / OBJECT: btnView (BaseClass: commandbutton, Parent: cntpeppol) ***
*** PROPERTIES ***
Top = 20

Left = 2

Height = 36

Width = 84

WordWrap = .T.

Caption = "Mostra Documento"

Name = "btnView"


*** METHODS ***
PROCEDURE Click

Local cStmt

Local nRes

** Verifico se esistono sia OPO che OPR (ordine peppol e ordine di revoca)

Text To cStmt TextMerge NoShow

	Select Case When Exists(Select * From DmsDocument where EntityTable = 'DOTES' and EntityId = <<FormatI4Spt(DoTes.Id_DoTes)>> And Tag = 'OPO') Then 1 Else 0 End + 

			 Case When Exists(Select * From DmsDocument where EntityTable = 'DOTES' and EntityId = <<FormatI4Spt(DoTes.Id_DoTes)>> And Tag = 'OPR') Then 2 Else 0 End

EndText 

nRes = xSqlExec2Var(cStmt)





If nRes = 0

	oApp.Dms.Show_DOTes_PEPPOLXML(DoTes.Id_DoTes)

Else



	Local nChoice



	MNewObject0(This.Parent, 'oMenu', 'ShortcutMenu', 'Libs\_BaseOthCtrl.vcx')

	This.Parent.oMenu.AddMenuBar('Mostra Ordine',,, 1)

	This.Parent.oMenu.AddMenuBar('Mostra Revoca',,, 2)

	nChoice = This.Parent.oMenu.ShowMenu(MRow(Thisform.Name), MCol(Thisform.Name))

	This.Parent.RemoveObject('oMenu')



	Do Case

		Case nChoice = 1

			oApp.Dms.Show_DOTes_PEPPOLXML(DoTes.Id_DoTes)



		Case nChoice = 2

			oApp.Dms.Show_DOTes_PEPPOLXMLR(DoTes.Id_DoTes)

	EndCase

	

EndIf 

ENDPROC


*======================================================================

*** CLASS / OBJECT: btnUpload (BaseClass: commandbutton, Parent: cntpeppol) ***
*** PROPERTIES ***
Top = 20

Left = 92

Height = 36

Width = 84

WordWrap = .T.

Caption = "Invia al Cliente"

Name = "btnUpload"


*** METHODS ***
PROCEDURE Click

Do Create_Peppol_DDT In 'Forms\Peppol.fxp' With Thisform, DoTes.Id_DOTes

ENDPROC


*======================================================================

*** CLASS / OBJECT: btnState (BaseClass: commandbutton, Parent: cntpeppol) ***
*** PROPERTIES ***
Top = 20

Left = 180

Height = 36

Width = 84

WordWrap = .T.

Caption = "Mostra Stato Documento"

Name = "btnState"


*** METHODS ***
PROCEDURE Click

Local oDoc, oState

Local cResult, cMsg



Do NewSataEng In 'Forms\Peppol.fxp' With Thisform



If Type('Thisform.oSata') = 'O'



	oDoc = xSqlExec2Obj("Select TimeIns, FileName From DmsDocument Where EntityTable = 'DOTES' and EntityId = " + FormatI4Spt(DoTes.Id_DoTes) + " And Use4Peppol = 1")

	

	If !IsEmpty(oDoc)

		oState = Thisform.oSata.StatoDDT(oDoc.TimeIns, JustStem(oDoc.FileName), @cResult)

		If !IsEmpty(oState)

			cMsg = 'Stati DDT' + CRLF + CRLF + 'InputFlowItemStatus:	' + oState.InputFlowItemStatus + Iif(oState.InputFlowItemStatus = 'SKIPPED', ' - ' + oState.SkipCause, '')

			If Type('oState.PeppolStatus') = 'C'

				cMsg = cMsg + CRLF + 'PeppolStatus		' + oState.PeppolStatus

			EndIf 

			cMsg = CHRTRAN(cMsg, '|', CHR(13) + CHR(10))

			xMessageBox(cMsg, 48)

		Else

			Error cResult

		EndIf 

	Else

		xMessageBox('Il DDT non è mai stato inoltrato alla rete PEPPOL.', 48)

	EndIf 

	

	

EndIf 

ENDPROC


*======================================================================

*** CLASS / OBJECT: cntfactoring (BaseClass: container, Parent: ) ***
*** PROPERTIES ***
Width = 270

Height = 66

BorderWidth = 0

Name = "cntfactoring"


*** METHODS ***
PROCEDURE Refresh

DoDefault()



** Visibile solo per fatture ciclo attivo

If PemStatus(Thisform, 'oFactoringEng', 5) And InList(DoTes.DOBitMask, 0x0000000008, 0x0000000010) And IsEmpty(DoTes.Cd_CF_Auto)



	** Verifico se la fattura è collegata ad un progetto Factoring

	If IsEmpty(DoTes.Id_FactoringProject)

		This.btnInvia			 .Visible = .T.		

		This.lblFactoringEvent.Visible = .T.		

		This.lblFactoringEvent.Caption = NEvl(Rtrim(DoTes.FactoringEvent), '')

		This.lblFactoringEvent.ToolTipText = This.lblFactoringEvent.Caption

		

		This.lblProgetti	.Visible = .F.

		This.lnkProgetto 	.Visible = .F.

		This.lnkContratto .Visible = .F.

		This.lblStato		.Visible = .F.

		This.lblStatoValue.Visible = .F.

		

		This.lnkProgetto.Caption = ''

		This.lnkProgetto.AddProperty('Link', '')

		This.lblStatoValue.Caption = ''



	Else



		This.lnkProgetto.Caption = Rtrim(DoTes.FactoringNumero)

		This.lnkProgetto.AddProperty('Link', DoTes.FactoringLink)

		This.lblStatoValue.Caption = DoTes.FactoringStatus			&& Thisform.oFactoringEng.DecodeStatus(oP.Status)					



		This.btnInvia			 .Visible = .F.	

		This.lblFactoringEvent.Visible = .F.

		This.lblFactoringEvent.Caption = ''

		This.lblFactoringEvent.ToolTipText = ''



		This.lblProgetti	.Visible = .T.

		This.lnkProgetto 	.Visible = .T.

		This.lnkContratto .Visible = InList(DoTes.FactoringStatus, 'In attesa erogazione', 'Credito erogato')

		This.lblStato		.Visible = .T.

		This.lblStatoValue.Visible = .T.		

	EndIf 

	This.Visible = .T.



Else

	This.Visible = .F.

EndIf 



ENDPROC

PROCEDURE Init

DoDefault()



If !oApp.LicInfo.DO_Factoring Or !oApp.oUser.AccessFactoring

	Return .F.

EndIf 



Set Procedure To 'Forms\Factoring.fxp' Additive

GetFactoringEng(Thisform)

If !PemStatus(Thisform, 'oFactoringEng', 5)

	Return .F.

EndIf 







ENDPROC


*======================================================================

*** CLASS / OBJECT: btnInvia (BaseClass: commandbutton, Parent: cntfactoring) ***
*** PROPERTIES ***
Top = 24

Left = 216

Height = 21

Width = 166

Caption = "Valuta la cessione del Credito"

Visible = .F.

ZOrderSet = 0

Name = "btnInvia"


*** METHODS ***
PROCEDURE Click

Local cMsg, cWhere

Local nId



Use In Select('DoTes2Factoring')



nId    = DoTes.Id_DoTes

cWhere = ' And DoTes.Id_DoTes = ' + FormatI4Spt(nId)

Thisform.oFactoringEng.GetDoTes2Factoring(cWhere)



Do Case

	Case RecCount('DoTes2Factoring') = 1



		Local oForm

		oForm = RunCmd('Cmd_Factoring', Thisform, nId)

		If !IsEmpty(oForm)

			oForm.Show(1)

		EndIf 

		

		** Visualizzo il dettaglio del progetto appena creato

		This.Parent.Refresh()

		This.Parent.lnkProgetto.Click()





	Case RecCount('DoTes2Factoring') = 0

		Text To cMsg TextMerge NoShow Pretext 1+2

		Il documento non può essere inviato per la valutazione del credito.

		

		Le condizioni da rispettare sono:

		 - documento emesso verso cliente italiano (non P.A.);

		 - documento elettronico consegnato al cliente;

		 - importo totale di almeno 1000 €;

		 - nessuna scadenza già incassata;

		 - una delle scadenze deve essere almeno a 30 gg dalla data di invio.

		EndText 

		xMessageBox(cMsg, 48)

		

EndCase 



Use In Select('DoTes2Factoring')

ENDPROC

PROCEDURE Init

DoDefault()



This.Left = 8

ENDPROC


*======================================================================

*** CLASS / OBJECT: lnkProgetto (BaseClass: label, Parent: cntfactoring) ***
*** PROPERTIES ***
AutoSize = .T.

FontUnderline = .T.

Caption = "XXXXXXX"

Left = 58

MousePointer = 15

Top = 23

ForeColor = 0,0,255

ZOrderSet = 3

Name = "lnkProgetto"


*** METHODS ***
PROCEDURE Click

If !IsEmpty(This.Link)

	Thisform.oFactoringEng.ShowProject(Alltrim(This.Link))

EndIf 

ENDPROC


*======================================================================

*** CLASS / OBJECT: lblFactoringEvent (BaseClass: label, Parent: cntfactoring) ***
*** PROPERTIES ***
Caption = "FactoringEvent"

Height = 16

Left = 204

Top = 48

Width = 64

ForeColor = 128,128,128

ZOrderSet = 4

Name = "lblFactoringEvent"


*** METHODS ***
PROCEDURE Init

DoDefault()



This.Left = 8

This.Width = 250

This.Anchor = 10

ENDPROC


*======================================================================

*** CLASS / OBJECT: lnkContratto (BaseClass: image, Parent: cntfactoring) ***
*** PROPERTIES ***
Picture = gen_factoring\agreement.png

Height = 24

Left = 180

MousePointer = 15

Top = 24

Width = 24

ToolTipText = "Vedi contratto"

pictureres = agreement.png@forms\gen_factoring.rll

Name = "lnkContratto"


*** METHODS ***
PROCEDURE Click

Local cStmt, cOutFile

Local nId_DmsDocument



Text To cStmt TextMerge NoShow

	Select Id_DmsDocument

	From DmsDocument

	Where EntityTable = 'FACTORINGPROJECT' And EntityId = <<FormatI4Spt(DoTes.FactoringId)>> And Tag = 'CON'

EndText 

nId_DmsDocument = xSqlExec2Var(cStmt)



If !IsEmpty(nId_DmsDocument)

	cOutFile = Addbs(oApp.TmpDir)

	oApp.Dms.Extract(nId_DmsDocument, @cOutFile) 	

	If File(cOutFile)

		ShellExecute(0, 'open', cOutFile, NULL, NULL, SW_NORMAL)

	EndIf 

EndIf 

ENDPROC


*======================================================================

*** CLASS / OBJECT: cntconservazioneinvio (BaseClass: container, Parent: ) ***
*** PROPERTIES ***
Width = 269

Height = 70

BackStyle = 1

BorderWidth = 0

BackColor = 255,255,255

Name = "cntconservazioneinvio"


*** METHODS ***
PROCEDURE Init

DoDefault()



This.ImgOperazioni.PictureRes  = "Images\Operazioni.png@Forms\Fedi_Doc.rll"

PictureRes2Picture(This.ImgOperazioni)



ENDPROC

PROCEDURE Refresh

Local cStmt





** Controllo se il record DMSDocument con tag PDF o FTE è stato mandato a ARKManager

Text To cStmt Textmerge NoShow

	If Exists(Select * From DmsDocument Where EntityTable = 'DOTES' And EntityId = << FormatI4Spt(DOTes.Id_DOTes) >> And Tag In ('PDF', 'FTE') And Id_ARKManager Is Not Null) 

		Select 1 

	Else

		Select 0

EndText 

This.imgConservato.Visible = xSqlExec2Var(cStmt) = 1

**



If IsEmpty(DoTes.FTE_Status)

	** Documenti diversi da Fatture elettroniche

	This.lblStatus.Visible = .F.

	This.imgStatus.Visible = .F.

	

	This.Title.Caption = ' ' + Upper(Decode_TipoDo(DoTes.TipoDocumento))

Else

	** Fatture elettroniche

	This.AddProperty('FTE_WorkFlow', xSqlExec2Obj('Select * From FTE_WorkFlow Where FTE_Status = ' + FormatC4Spt(DoTes.FTE_Status)))



	This.lblStatus.Caption 		= 	 Rtrim(This.FTE_WorkFlow.Bar_Caption)

	This.lblStatus.TooltipText = 	 Rtrim(This.FTE_WorkFlow.Bar_TooltipText)

	This.lblStatus.Visible 		= !IsNull(This.FTE_WorkFlow.Bar_Step)

	*ObjMov(This.lblStatus, This.imgStatus.Right + 1, This.imgStatus.Top + 5 )



	If This.FTE_WorkFlow.Bar_IsLink = 1

		This.lblStatus.FontUnderline = .T.

		This.lblStatus.ForeColor 	  = Rgb(0,0,255)

		This.lblStatus.MousePointer  = 15 

	Else

		This.lblStatus.FontUnderline = .F.			&& non voglio mostare l'aspetto da link

		This.lblStatus.ForeColor 	  = Rgb(0,0,0)			

		This.lblStatus.MousePointer  = 0 	

	EndIf  



	This.imgStatus.Visible = This.lblStatus.Visible



	This.imgStatus.PictureRes = "Images\" + Rtrim(Iif(IsEmpty(DOTes.CodiceFPR), This.FTE_WorkFlow.Image_PA, This.FTE_WorkFlow.Image_B2B)) + "@Forms\Fedi_Doc.rll"

	PictureRes2Picture(This.imgStatus)



	This.Title.Caption = ' FATTURAZIONE ELETTRONICA'



EndIf 

ENDPROC


*======================================================================

*** CLASS / OBJECT: lblStatus (BaseClass: label, Parent: cntconservazioneinvio) ***
*** PROPERTIES ***
Caption = "_________________"

Height = 16

Left = 52

Top = 51

Width = 125

ZOrderSet = 1

Name = "lblStatus"


*** METHODS ***
PROCEDURE Click

Local nId_DmsDocument, nChoice

Local oMenu

 

nChoice = 0

 

If !IsEmpty(This.Parent.FTE_WorkFlow.DMS_Tag)



	If This.Parent.FTE_WorkFlow.DMS_Tag = 'MC' And !DoTes.EntePubblico

		oMenu = NewObject0('ShortcutMenu', 'Libs\_BaseOthCtrl.vcx')

		oMenu.AddMenuBar('Invia mail informativa al Cliente',,, 1)

		oMenu.AddMenuBar('Vedi esito'								 ,,, 2)

		nChoice = oMenu.ShowMenu()

	Else

		nChoice = 2		

	EndIf 

EndIf 



Do Case 

	Case nChoice = 1

		Do FE_InvioMail_MC In 'Forms\Cmd_FTE.fxp' With This, DoTes.Cd_CF, DoTes.Id_DoTes, DoTes.NumeroDoc, DoTes.DataDoc

	

	Case nChoice = 2

		nId_DmsDocument = xSqlExec2Var("Select Id_DmsDocument From DmsDocument Where EntityTable = 'DOTES' And EntityId = " + FormatI4Spt(DoTes.Id_DoTes) + " And Tag = " +  FormatC4Spt(DOTes.FTE_Status))

		If !IsEmpty(nId_DmsDocument)	

			FTE_Show(nId_DmsDocument)

		Else

			xMessageBox('Nessun documento da visualizzare', 48)

		EndIf 

EndCase 

ENDPROC


*======================================================================

*** CLASS / OBJECT: imgConservato (BaseClass: image, Parent: cntconservazioneinvio) ***
*** PROPERTIES ***
Picture = ..\images\included\conservato.bmp

Stretch = 1

Height = 32

Left = 192

Top = 24

Visible = .F.

Width = 32

ZOrderSet = 3

Name = "imgConservato"


*** METHODS ***
PROCEDURE Init

DoDefault()



SetObjPicture(This, 'images\included\conservato.bmp')

ENDPROC


*======================================================================

*** CLASS / OBJECT: imgOperazioni (BaseClass: image, Parent: cntconservazioneinvio) ***
*** PROPERTIES ***
Picture = fedi_doc\images\operazioni.png

Height = 24

Left = 7

MousePointer = 15

Top = 26

Width = 24

ZOrderSet = 8

ToolTipText = "Operazioni"

pictureres = .T.

Name = "imgOperazioni"


*** METHODS ***
PROCEDURE Click

Local oMenu

Local nChoice

Local cStmt



** Se non esiste il record DMS con tag=PDF ed è previsto dalla configurazione doc, allora lo creo d'ufficio.

Text To cStmt TextMerge NoShow

	If Exists(Select * From DmsDocument Where Tag = 'PDF' And EntityTable = 'DOTES' And EntityId = << FormatI4Spt(DOTes.Id_DOTes) >>) 

		Select 1 

	Else 

		-- non c'è il record PDF, vedo se la configurazione DO lo prevede

		If Exists(Select * From DO Where Cd_DO = << FormatC4Spt(DOTes.Cd_DO) >> And AutoArchivia = 1) Select 0 Else Select 1

EndText 

If xSqlExec2Var(cStmt) = 0

	oApp.Dms.Attach_DoTes_PDF(DOTes.Id_DoTes)

EndIf 



** Menu --------------------------------------



** Elenco tutti gli allegati disponibili per il documento corrente (PDF + FEPA)

Text To cStmt Textmerge Noshow



	Select DocumentDate, Riga = -2, Id_DmsDocument, Caption = 'Vedi Documento PDF (' + 	Convert(Varchar(10), DocumentDate, 5) + ')', Tag, Descrizione, FileName

	From DmsDocument D

	Where D.EntityTable = 'DOTES' And D.EntityId = <<FormatI4Spt(DoTes.Id_DoTes)>> And D.Tag = 'PDF'



	Union



	Select DocumentDate, Riga = -1, Id_DmsDocument, 'Vedi Fattura Elettronica (xml) (' + Convert(Varchar(10), DocumentDate, 5) + ')', Tag, Descrizione, FileName

	From DmsDocument D

	Where D.EntityTable = 'DOTES' And D.EntityId = <<FormatI4Spt(DoTes.Id_DoTes)>> And D.Tag = 'FTE'



	Union



	Select DocumentDate, Riga = 0, Id_DmsDocument, 'INFO Fattura Elettronica', Tag = 'FTEINFO', Descrizione, FileName

	From DmsDocument D

	Where D.EntityTable = 'DOTES' And D.EntityId = <<FormatI4Spt(DoTes.Id_DoTes)>> And D.Tag = 'FTE'



	Union

		

	Select DocumentDate, W.Riga, D.Id_DmsDocument, 'Esito ' + W.DMS_Tag + ' ' + W.Bar_Caption  + ' (' + Convert(Varchar(10), DocumentDate, 5) + ')', Tag, Descrizione, FileName

	From DmsDocument D

		Join FTE_WorkFlow W On W.FTE_Status = D.Tag 

	Where D.EntityTable = 'DOTES' And D.EntityId = <<FormatI4Spt(DoTes.Id_DoTes)>> And W.DMS_Tag Is Not Null And D.Tag != 'FTE'



	Union



	Select DocumentDate, Riga = 99, Id_DmsDocument, 'Notifica Metadati', Tag, Descrizione, FileName

	From DmsDocument D

	Where D.EntityTable = 'DOTES' And D.EntityId = <<FormatI4Spt(DoTes.Id_DoTes)>> And D.Tag = 'MT'



	Order by 1, 2

EndText 

xSqlExec(cStmt, 'mnuitems')



** Se la fattura non è già stata CONSERVATA, mostro la voce per farlo....

If !This.Parent.imgConservato.Visible And oApp.LicInfo.ArchiviazioneSost AND (!IsEmpty(oApp.ArkManagerConfig.Url) Or !IsEmpty(oApp.ArkManagerConfig.Username) Or !IsEmpty(oApp.ArkManagerConfig.Password))

	Insert Into mnuItems(Caption) 		Values ('\-')

	Insert Into mnuItems(Caption, Tag) 	Values ('Manda in conservazione', 'ARK')

EndIf 



** Conservazione Smart

If Type('oApp.ConservazioneSmartConfig') = 'O'

	Locate For Riga = -1

	If Found()

		Insert Into mnuItems(Caption) 		Values ('\-')

		Insert Into mnuItems(Caption, Tag) 	Values ('Conservazione SMART...', 'CSM')

	EndIf 

EndIf 



MNewObject0(This.Parent, 'oMenu', 'ShortcutMenu', 'Libs\_BaseOthCtrl.vcx')

Scan

	This.Parent.oMenu.AddMenuBar(mnuItems.Caption,,, Recno('mnuitems'))

EndScan 		

nChoice = This.Parent.oMenu.ShowMenu(MRow(Thisform.Name), MCol(Thisform.Name))

This.Parent.RemoveObject('oMenu')



If nChoice > 0



	** Visualizzazione



	Select mnuItems

	Go (nChoice)



	Do Case 

		Case mnuItems.Tag = 'ARK'

			** Manda in conservazione

			DOTES_ARK_RegistraDocumento()



			Thisform.DE.DoTes.RequeryCurrent()

			Thisform.OnRecordChange()		&& mi serve per aggiornare i bottoni della Toolbar

			

		Case mnuItems.Tag = 'PDF'

			oApp.Dms.Show_DOTes_PDF(DoTes.Id_DoTes)



		Case mnuItems.Tag = 'FTEINFO'



			Local nTop, nLeft, nRecNo



			nTop  = Thisform.Toolbar.Top + Thisform.Toolbar.Height

			nLeft = Thisform.Toolbar.Buttons('FTEVIEW').Left



			Do DOTes_Show_FTEInfo In 'Forms\Cmd_FTE.fxp' With Thisform, DoTes.Id_DoTes, nTop, nLeft





		Case mnuItems.Tag = 'CSM'



			RunCmdWS('cmd_ConservazioneSmart.vcx', Thisform, DoTes.Id_DoTes, Iif(Left(DoTes.Cd_CF, 1) = 'C', 'DOTES_CA', 'DOTES_CP'))



			Thisform.DE.DoTes.RequeryCurrent()

			Thisform.OnRecordChange()		&& mi serve per aggiornare i bottoni della Toolbar



		OtherWise

			** Fattura Elettronica o Esiti

			FTE_Show(mnuItems.Id_DmsDocument)

			This.Parent.Refresh()

	EndCase  



EndIf 



Use in mnuItems

ENDPROC


*======================================================================

*** CLASS / OBJECT: imgStatus (BaseClass: image, Parent: cntconservazioneinvio) ***
*** PROPERTIES ***
Height = 24

Left = 50

Top = 26

Width = 128

ZOrderSet = 9

Name = "imgStatus"


*** METHODS ***
PROCEDURE refresh

This.Parent.Line2.Visible = This.Visible 



** Posiziono l'icona della conservazione

If This.Parent.Line2.Visible

	ObjMov(This.Parent.imgConservato, This.Parent.Line2.Left + 8)

Else

	ObjMov(This.Parent.imgConservato, This.Parent.Line1.Left + 8)

EndIf 

ENDPROC


*======================================================================

*** CLASS / OBJECT: pgrighe (BaseClass: container, Parent: ) ***
*** PROPERTIES ***
Width = 726

Height = 296

BorderWidth = 0

Name = "pgrighe"


*** METHODS ***
PROCEDURE modifycolumnslook

Local oDO, oCGCausale



Iif(Empty(ThisForm.PF.pgGenerale.txtCd_DO.Field.FKAlias), ThisForm.PF.pgGenerale.txtCd_DO.Field.Refresh(), .T.)

oDO = ThisForm.PF.pgGenerale.txtCd_DO.Field.FkRecord



With This.Grid



	.ColCd_AR.StdText1.CheckFor 	= ATC(Left(DoTes.Cd_CF, 1), 'CF')



	.ColDataConsegna.Enabled		= !ThisForm.CopiaDataConsegna



	.ColCd_MG_A.Enabled 				= !ThisForm.MagAFix

	.ColCd_MG_A.Visible 				=  ThisForm.MagAFlag

	.ColCd_MGUbicazione_A.Visible =  ThisForm.MagAFlag



	.ColCd_MG_P.Enabled 				= !ThisForm.MagPFix

	.ColCd_MG_P.Visible 				=  ThisForm.MagPFlag

	.ColCd_MGUbicazione_P.Visible =  ThisForm.MagPFlag



**	.ColCd_ARLotto.Visible			= ThisForm.MagAFlag Or ThisForm.MagPFlag

	.ColTipoPC.Visible				= ThisForm.DE.Preferenza.DOAbilitaTipoPC And oDO.UIAbilitaTipoPC



	.ColCd_CAVda.Visible				= oDO.CAEnabled

	.ColCd_CACda.Visible				= oDO.CAEnabled

	.ColCd_CAFormula.Visible		= oDO.CAEnabled



	** Il periodo e la durata li visualizzo solo se è impostato a true il flag Preferenza.CACGPeriodo

	If !Thisform.DE.Preferenza.CACGPeriodo

		.ColCAPartenza.Visible			= oDO.CAEnabled

		.ColCADurata.Visible			= oDO.CAEnabled

	Else

		.ColCAPartenza.Visible			= .F.

		.ColCADurata.Visible			= .F.

	EndIf





	.ColQtaEvadibile.Visible		= !(oDO.TipoDocumento $ 'FAN')



	.ColRR_Cd_CGConto.Visible 		= (oDO.RR_Enabled)



	** DOCIVATI

	.ColPrezzoUnitarioV.PrezzoUnitarioV.Caption = 'Prezzo Un.' + Iif(DoTes.ImportiIvati, ' Ivato', '')

	

	** DICHINT

	.ColDOIntento.Visible			= Thisform.DoIntento_Visible()



	** FIFO CONTINUO, COLONNA DI RIFERIMENTO AL RIGO DI CARICO

	.ColId_MGMov_Carico.Visible	= oDO.FFC_MostraRiferimentoCarico

			

EndWith



Thisform.SetRegimeIva('COLSINTERFACE')



ENDPROC

PROCEDURE grid_onvaluechange

LParameters oControl, lFromDetailForm, xOldValue



Local cControlSource, oCol, vRet, cPFix



** Le date trattate con DateTimeLikeDate hanno come cs 'This.DataSource' ed il vero CS in TrueControlSource

cPFix = Iif(PemStatus(oControl, 'DateTimeLikeDate', 5) And oControl.DateTimeLikeDate And !Empty(oControl.TrueControlSource), 'True', '')

cControlSource = AllTrim(Lower(oControl.&cPfix.ControlSource))



If Empty(cControlSource)		

	** Quando vengono invocati i metodi .SaveRecordSource e RestoreRecordSource della griglia, si 

	** scatenano le Valid e si riesce ad arrivare in punti come questo con il ControlSource vuoto

	Return

Else

	** Se il ControlSource è composto ricavo solo il nome del campo

	cControlSource = Iif(At('.', cControlSource) > 0, JustExt(cControlSource), cControlSource)

EndIf



** Creazione dei riferimenti ausiliari

AddProperty(oControl, 'Thisform', Iif(lFromDetailForm, This.RowDetailForm, Thisform))

AddProperty(oControl, 'Fediform', Thisform                                          )



** Rigiro la chiamata

vRet = This.Ctrls_OnValueChange(cControlSource, oControl, xOldValue)



** Ricalcolo tutti i campi calcolati

This.SetDoRig_Formulae()

This.SetDoRig_PostFormulae()



** Rimozione dei riferimenti ausiliari

oControl.Thisform = Null

oControl.Fediform = Null



** Refresh: avendo cambiato il cursore è bene rinfrescare i controlli collegati

If lFromDetailForm

	** Devo scatenare il refresh di tutta la pagina

	This.RowDetailForm.PF.pgGenerale.Refresh()

Else

	** Devo scatenare il refresh controllo per controllo

	For Each oCol In This.Grid.Columns

		oCol.Controls[2].Refresh()

	EndFor

EndIf



Return vRet

ENDPROC

PROCEDURE grid_when

Lparameters oControl, lFromDetailForm



Local cControlSource, oCol, vRet, cPFix



** Le date trattate con DateTimeLikeDate hanno come cs 'This.DataSource' ed il vero CS in TrueControlSource

cPFix = Iif(PemStatus(oControl, 'DateTimeLikeDate', 5) And oControl.DateTimeLikeDate And !Empty(oControl.TrueControlSource), 'True', '')

cControlSource = AllTrim(Lower(oControl.&cPfix.ControlSource))



If Empty(cControlSource)		

	** Quando vengono invocati i metodi .SaveRecordSource e RestoreRecordSource della griglia, si 

	** scatenano le Valid e si riesce ad arrivare in punti come questo con il ControlSource vuoto

	Return

Else

	** Se il ControlSource è composto ricavo solo il nome del campo

	cControlSource = Iif(At('.', cControlSource) > 0, JustExt(cControlSource), cControlSource)

EndIf



** Creazione dei riferimenti ausiliari

AddProperty(oControl, 'Thisform', Iif(lFromDetailForm, This.RowDetailForm, Thisform))

AddProperty(oControl, 'Fediform', Thisform                                          )



** Rigiro la chiamata

vRet = This.Ctrls_When(cControlSource, oControl)



** Rimozione dei riferimenti ausiliari

oControl.Thisform = Null

oControl.Fediform = Null



** [from Fabio]: A cosa serve refreshare tutto nalla when(), Non di dovrebbero modificare i dati del cursore

** per cui risulta un appesantimento inutile eseguire refresh() di tutto.

** Avendo riscritto in modo corretto e centralizzato le when(), eseguendo soltanto test senza ricalcolo di valori si sono risolti

** anche alcuni problemi di uncommitted changes che si verificavano dando il fuoco su alcune colonne della COAN ed RR anche in SHOWMODE



** Refresh: avendo cambiato il cursore è bene rinfrescare i controlli collegati

**	If lFromDetailForm

**		** Devo scatenare il refresh di tutta la pagina

**		This.RowDetailForm.PF.pgGenerale.Refresh()

**	Else

**		** Devo scatenare il refresh controllo per controllo

**		For Each oCol In This.Grid.Columns

**			oCol.Controls[2].Refresh()

**		EndFor

**	EndIf



Return vRet



ENDPROC

PROCEDURE controllogiacenza

** lo stesso codice è stato replicato in cmd_doprelievocreazione



** Sono posizionato in DORig, la chiamata e` effettuata da Grid_onvalueChange ... Qta e Cd_MG_P

Local cAliasDo, cStmt, cEsercizio

Local lChkGiacenza, lchkDisponibile, lChkDisponibileImmediato, lReplaceQta

Local oRec, nRec, oAR

Local nChoice, nNewQta, nTotQta, nTotQtaOld, cCd_MG_P, cCd_AR, cCd_DO, nFattoreToUM1

Local nEsistenzaQ, nDisponibileQ, nDisponibileImmediatoQ



Select DORig



cCd_DO						 = ThisForm.PF.pgGenerale.txtCd_DO.Field.Value

cAliasDo 					 = ThisForm.PF.pgGenerale.txtCd_DO.Field.FKAlias

lChkGiacenza			 	 = Eval(cAliasDo + '.UIChkGiacenza')

lchkDisponibile			 = Eval(cAliasDo + '.UIChkDisponibile')

lChkDisponibileImmediato = Eval(cAliasDo + '.UIChkDisponibileImmediato')

cCd_MG_P						 = DoRig.Cd_MG_P

cCd_AR 						 = DoRig.Cd_AR

nNewQta						 = DoRig.Qta

nOldQta						 = DoRig.Qta

nFattoreToUM1				 = DORig.FattoreToUM1

oAR 							 = xSqlExec2Obj('Select Fittizio, DBKit From AR Where Cd_AR = ' + FormatC4Spt(cCd_AR)) 	&& Per gli articoli fittizi e Kit non faccio alcun controllo visto che non movimentano il magazzino



If IsEmpty(cCd_MG_P) Or IsEmpty(nNewQta) Or IsEmpty(cCd_AR) Or (!lChkGiacenza And !lchkDisponibile And !lChkDisponibileImmediato) Or oAR.Fittizio Or oAR.DBKit

	Return DoRig.Qta

EndIf



nRec = Recno('DORig')



Calculate Sum(DoRig.Qta * DORig.FattoreToUM1) 										To nTotQta		For DoRig.Cd_MG_P = cCd_MG_P And DoRig.Cd_AR = cCd_AR In DORig

Calculate Sum(Oldval('Qta', 'DORig') * Oldval('FattoreToUM1', 'DORig')) To nTotQtaOld 	For DoRig.Cd_MG_P = cCd_MG_P And DoRig.Cd_AR = cCd_AR In DORig



Locate Record (nRec)



cEsercizio = ''



Asp_MGEsercizio(DOTes.DataDoc, @cEsercizio)



If lchkDisponibile = .T. Or lChkDisponibileImmediato = .T.

	TEXT TO cStmt NOSHOW TEXTMERGE

		SELECT

			Quantita		 As EsistenzaQ,

			QuantitaDisp As DisponibileQ,

			QuantitaDimm As DisponibileImmediatoQ

		FROM MGDisp(<<Format4Spt(cEsercizio)>>) MGDisponibile

		WHERE

			Cd_AR 			= <<Format4Spt(cCd_AR)>> AND

			Cd_MG 			= <<Format4Spt(cCd_MG_P)>>

	ENDTEXT

Else

	TEXT TO cStmt NOSHOW TEXTMERGE

		SELECT

			Quantita						  As EsistenzaQ,

			Convert(Numeric(18,8), 0) As DisponibileQ,

			Convert(Numeric(18,8), 0) As DisponibileImmediatoQ

		FROM MGGiac(<<Format4Spt(cEsercizio)>>) MGGiacenza

		WHERE

			Cd_AR 			= <<Format4Spt(cCd_AR)>> AND

			Cd_MG 			= <<Format4Spt(cCd_MG_P)>>

	ENDTEXT

EndIf



oRec = xSqlExec2Obj(cStmt)



If IsNull(oRec)

	oRec = CreateObject('Empty')

	AddProperty(oRec, 'EsistenzaQ'				, 0)

	AddProperty(oRec, 'DisponibileQ'				, 0)

	AddProperty(oRec, 'DisponibileImmediatoQ'	, 0)

EndIf



nEsistenzaQ 				= oRec.EsistenzaQ					+ nTotQtaOld

nDisponibileQ 				= oRec.DisponibileQ				+ nTotQtaOld

nDisponibileImmediatoQ 	= oRec.DisponibileImmediatoQ	+ nTotQtaOld



oRec.EsistenzaQ 				= Max(oRec.EsistenzaQ 				+ nTotQtaOld, 0)

oRec.DisponibileQ 			= Max(oRec.DisponibileQ 			+ nTotQtaOld, 0)

oRec.DisponibileImmediatoQ = Max(oRec.DisponibileImmediatoQ + nTotQtaOld, 0)



lReplaceQta	= .F.



If lChkGiacenza And (oRec.EsistenzaQ < nTotQta)

	Text To cMessage NoShow Pretext 1+2

		Nel documento di tipo <%1!>, la riga dell'articolo %2! presenta una quantità tale che la richiesta sia superiore alla giacenza.

		Magazzino %3! : Quantità riga = %4! / Quantità documento = %5! / Giacenza = %6! [%7!]

		

		Imposto la quantità in modo tale che la quantità totale non superi la Giacenza?

	EndText 

	cMessage = Thisform.TB_(,'EB08961A-D160-43CD-9720-1154DAF9C24C', cMessage, Rtrim(cCd_DO), RTrim(cCd_AR), Rtrim(cCd_MG_P), Tran(nNewQta), Tran(nTotQta / nFattoreToUM1), Trans(oRec.EsistenzaQ / nFattoreToUM1), Tran(nEsistenzaQ / nFattoreToUM1))



	If xMessageBox(cMessage, MB_ICONQUESTION + MB_YESNO + MB_DEFBUTTON2) == IDYES 

		lReplaceQta = .T.

		nNewQta = Max((oRec.EsistenzaQ - nTotQta) / nFattoreToUM1 + nOldQta, 0)

		nTotQta = nTotQta + (nNewQta - nOldQta) * nFattoreToUM1

		nOldQta = nNewQta

	EndIf 

EndIf



If lchkDisponibile And (oRec.DisponibileQ < nTotQta)

	Text To cMessage NoShow Pretext 1+2

		Nel documento di tipo <%1!>, la riga dell'articolo %2! presenta una quantità tale che la richiesta sia superiore al disponibile.

		Magazzino %3! : Quantità riga = %4! / Quantità documento = %5! / Disponibile = %6! [%7!]

		

		Imposto la quantità in modo tale che la quantità totale non superi il Disponibile?

	EndText

	cMessage = Thisform.TB_(,'74606D99-63F0-4070-9D90-BF09EBF20009', cMessage, Rtrim(cCd_DO), RTrim(cCd_AR), Rtrim(cCd_MG_P), Tran(nNewQta), Tran(nTotQta / nFattoreToUM1), Tran(oRec.DisponibileQ / nFattoreToUM1), Tran(nDisponibileQ / nFattoreToUM1))

	

	If xMessageBox(cMessage, MB_ICONQUESTION + MB_YESNO + MB_DEFBUTTON2) == IDYES 

		lReplaceQta = .T.

		nNewQta = Max((oRec.DisponibileQ - nTotQta) / nFattoreToUM1 + nOldQta, 0)

		nTotQta = nTotQta + (nNewQta - nOldQta) * nFattoreToUM1

		nOldQta = nNewQta

	EndIf 

EndIf



If lChkDisponibileImmediato And (oRec.DisponibileImmediatoQ < nTotQta)

	Text To cMessage NoShow Pretext 1+2

		Nel documento di tipo <%1!>, la riga dell'articolo %2! presenta una quantità tale che la richiesta sia superiore al disponibile immediato.

		Magazzino %3! : Quantità riga = %4! / Quantità documento = %5! / Disponibile immediato = %6! [%7!]

		

		Imposto la quantità in modo tale che la quantità totale non superi il Disponibile immediato?

	EndText 

	cMessage = Thisform.TB_(,'D8DD7278-66E6-45CE-87D7-98B2E1D910CF', cMessage, Rtrim(cCd_DO), RTrim(cCd_AR), Rtrim(cCd_MG_P), Tran(nNewQta), Tran(nTotQta / nFattoreToUM1), Tran(oRec.DisponibileImmediatoQ / nFattoreToUM1), Tran(nDisponibileImmediatoQ / nFattoreToUM1))



	If xMessageBox(cMessage, MB_ICONQUESTION + MB_YESNO + MB_DEFBUTTON2) == IDYES 

		lReplaceQta = .T.

		nNewQta = Max((oRec.DisponibileImmediatoQ - nTotQta) / nFattoreToUM1 + nOldQta, 0)

		nTotQta = nTotQta + (nNewQta - nOldQta) * nFattoreToUM1

		nOldQta = nNewQta

	EndIf 

EndIf



If lReplaceQta

	Return nNewQta

Else

	Return DoRig.Qta

EndIf









ENDPROC

PROCEDURE grid_isvalid

Lparameters oControl, lFromDetailForm, xOldValue, lIsChanged



Local cControlSource, oCol, vRet, cPFix



** Le date trattate con DateTimeLikeDate hanno come cs 'This.DataSource' ed il vero CS in TrueControlSource

cPFix = Iif(PemStatus(oControl, 'DateTimeLikeDate', 5) And oControl.DateTimeLikeDate And !Empty(oControl.TrueControlSource), 'True', '')

cControlSource = AllTrim(Lower(oControl.&cPfix.ControlSource))



If Empty(cControlSource)		

	** Quando vengono invocati i metodi .SaveRecordSource e RestoreRecordSource della griglia, si 

	** scatenano le Valid e si riesce ad arrivare in punti come questo con il ControlSource vuoto

	Return

Else

	** Se il ControlSource è composto ricavo solo il nome del campo

	cControlSource = Iif(At('.', cControlSource) > 0, JustExt(cControlSource), cControlSource)

EndIf



** Creazione dei riferimenti ausiliari

AddProperty(oControl, 'Thisform', Iif(lFromDetailForm, This.RowDetailForm, Thisform))

AddProperty(oControl, 'Fediform', Thisform                                          )



** Rigiro la chiamata

vRet = This.Ctrls_IsValid(cControlSource, oControl, lIsChanged, xOldValue)



** Rimozione dei riferimenti ausiliari

oControl.Thisform = Null

oControl.Fediform = Null



** Refresh: avendo cambiato il cursore è bene rinfrescare i controlli collegati

If lFromDetailForm

	** Devo scatenare il refresh di tutta la pagina

	This.RowDetailForm.PF.pgGenerale.Refresh()

Else

	** Devo scatenare il refresh controllo per controllo

	For Each oCol In This.Grid.Columns

		oCol.Controls[2].Refresh()

	EndFor

EndIf



Return vRet



ENDPROC

PROCEDURE getevasodainfo

Lparameters nId_DoRig



Local cStmt, oRes



If Nvl(nId_DoRig, 0) <= 0		&& Riga appena inserita!!!

	Return ''

Else

	Text To cStmt NoShow TextMerge

		Declare @DocInfo Varchar(8000)

		Select @DocInfo = ''

		Select

			@DocInfo = @DocInfo + Char(13) + Cd_Do + ' ' + LTrim(Rtrim(NumeroDoc)) + ' del ' + Convert(VarChar(10), DataDoc, 105) + ' - Riga ' + Convert(Varchar(10), Riga)

		From DoRig Where Id_DoRig_Evade = <<nId_DoRig>> Order By Id_DoTes

		Select @DocInfo As DocEvadenti

	EndText 

	oRes = xSqlExec2Obj(cStmt)

	Return Iif(!IsNull(oRes), Rtrim(Substr(oRes.DocEvadenti,2)), '')		&& Tolgo CR iniziale

EndIf 

ENDPROC

PROCEDURE getevadeinfo

Lparameters nId_DoRig_Evade



Local cStmt, oRes



If Nvl(nId_DoRig_Evade, 0) <= 0		&& La riga non evade nulla

	Return ''

Else

	Text To cStmt NoShow TextMerge

		Select

			Cd_Do + ' ' + LTrim(Rtrim(NumeroDoc)) + ' del ' + Convert(VarChar(10), DataDoc, 105) + ' - Riga ' + Convert(Varchar(10), Riga) As DocEvaso

		From DoRig Where Id_DoRig = <<nId_DoRig_Evade>>

	EndText

	oRes = xSqlExec2Obj(cStmt)

	Return Iif(!IsNull(oRes), Rtrim(oRes.DocEvaso), '')

EndIf



ENDPROC

PROCEDURE setdorig_defaults

Lparameters cCd_AR, nQta, cDescr



Local oRec



** Invoco la funzione per i default di riga e non passo Cd_ARMisura e FattoreToUM1 in modo da ottenere in output i valori di default



oRec = DoRig_Defaults_2Obj_Ex(.T., DoTes.Cd_Do, DoTes.Cd_CF, DoTes.DataDoc, DoTes.DataConsegna, DoTes.Cd_CFDest, DoTes.Cd_Agente_1, DoTes.Cd_Agente_2, DoTes.Cd_PG, DoTes.Cd_LS_1, DoTes.Cd_LS_2, DoTes.Cd_VL, DoTes.Cambio, cCd_AR, nQta, Null, Null, DoRig.Cd_DoSottoCommessa)



If IsNull(oRec.Cambio_VL_LS) And IsNull(oRec.DataCambio_VL_LS)

	xMessageBox(Thisform.TB_(,'B13CDD79-030F-4394-A8E6-539FD43ACDDF', 'La valuta "%1!" associata al listino non ha alcun fixing. Non è stato possibile eseguire la conversione.', oRec.Cd_VL_LS), 48)

EndIf 

		

** ----- LICADAPTER

If !oApp.LicInfo.CA_Main

	oRec.Cd_CAVda 		= Null

	oRec.Cd_CACda		= Null

	oRec.Cd_CAFormula	= Null

	oRec.CAPartenza	= 0

	oRec.CADurata		= 1

EndIf



Replace ;

	Cd_AR							With NEvl(DoRig.Cd_AR,	cCd_AR				)	;		&& Così in inserimento batch di righe documento posso chiamare questo metodo passandogli il codice articolo.

	Descrizione					With NEvl(cDescr,			oRec.Descrizione	)	;

	DataConsegna 				With oRec.DataConsegna				;

	Cd_ARMisura					With oRec.Cd_ARMisura				;

	FattoreToUM1				With oRec.FattoreToUM1				;

	Cd_Aliquota					With oRec.Cd_Aliquota 				;

	Cd_ReverseCharge			With xDefault(DoTes.Cd_ReverseCharge, oRec.Cd_ReverseCharge) ;

	Cd_CGConto					With oRec.Cd_CGConto 				;

	Qta							With oRec.Qta							;

	QtaEvadibile				With oRec.Qta							;

	Cd_MG_A						With oRec.Cd_MG_A						;

	Cd_MGUbicazione_A			With oRec.Cd_MGUbicazione_A		;

	Cd_MG_P						With oRec.Cd_MG_P						;

	Cd_MGUbicazione_P			With oRec.Cd_MGUbicazione_P		;

	Cd_ARLotto					With oRec.Cd_ARLotto					;

	Cd_DOSottocommessa		With oRec.Cd_DOSottocommessa		;

	Cd_CAVda						With oRec.Cd_CAVda					;

	Cd_CACda						With oRec.Cd_CACda					;

	Cd_CAFormula				With oRec.Cd_CAFormula				;

	CAPartenza					With oRec.CAPartenza					;

	CADurata						With oRec.CADurata					;

	Evadibile					With oRec.Evadibile,					;

	Omaggio						With oRec.Omaggio						;

	Cambio						With oRec.Cambio						;

	DecimaliPrzUn				With oRec.DecimaliPrzUn				;

	Decimali						With oRec.Decimali					;

	PrezzoUnitarioV			With oRec.PrezzoUnitarioV			;

	PrezzoAddizionaleV		With oRec.PrezzoAddizionaleV		;

	Id_LSArticolo				With oRec.Id_LSArticolo				;

	Id_LSScaglione				With oRec.Id_LSScaglione			;

	ScontoRiga					With oRec.ScontoRiga					;

	ScontoAddizionale			With oRec.ScontoAddizionale		;

	ProvvigioneRiga_1			With oRec.ProvvigioneRiga_1		;

	ProvvigioneRiga_2			With oRec.ProvvigioneRiga_2		;

	ImportiIvati				With oRec.ImportiIvati				;

In DoRig



** Aggiungo le info relative alla gestione delle RR (non mi appoggio alla DORIG_DEFAULTS STD)

This.Setdorig_Defaults_RR()

This.Setdorig_Defaults_CG(oRec.Cd_CGConto)

This.Setdorig_Defaults_DI('DEF')



ENDPROC

PROCEDURE setdorig_prezzo

Lparameters nQtaNew, nQtaOld, lForce



** lForce BYREF  se si forza il ricalcolo del Prezzo/Sconto/Provv in base allo scaglione, allora questo parametro sarà messo a .T.



Local nFlag, oRec, lDoUpdate, nId_LSScaglioneNew, nId_LSScaglioneOld, cStmt, oObj



nFlag = Thisform.DE.Preferenza.DOPrezziPerQta



** nFlag può avere i seguenti valori:

**

** 1 - Non Variare

** 2 - Chiedi Conferma

** 3 - Varia senza chiedere conferma



If Empty(nQtaOld) Or InList(nFlag, 2, 3)

	

	oRec = DoRig_Defaults_Prezzo_2Obj(DoTes.Cd_DO, DoTes.Cd_CF, DoTes.DataDoc, DoRig.DataConsegna, DoTes.Cd_CFDest, DoTes.Cd_Agente_1, DoTes.Cd_Agente_2, DoTes.Cd_PG, DoTes.Cd_LS_1, DoTes.Cd_LS_2, DoTes.Cd_VL, DoTes.Cambio, DoRig.Cd_AR, nQtaNew, DoRig.Cd_ARMisura, DoRig.FattoreToUM1)

	

	If Empty(nQtaOld) Or !IsEmpty(oRec.Id_LSScaglione)

	

		If !Empty(nQtaOld)

			** Scaglione Nuovo

			nId_LSScaglioneNew = oRec.Id_LSScaglione

			

			** Scaglione Vecchio

			Text To cStmt TextMerge Noshow

				Declare @AScaglioni     Bit

				Declare @Id_LSScaglione Integer



				Select Top 1

					@AScaglioni     = LSA.AScaglioni,

					@Id_LSScaglione = LSS.Id_LSScaglione

				From LSArticolo LSA

					Left Outer Join LSScaglione LSS On LSS.Id_LSArticolo = LSA.Id_LSArticolo And LSS.FinoAQta >= << Format4Spt(nQtaOld) >>

				Where LSA.Id_LSArticolo = << Format4Spt(oRec.Id_LSArticolo) >>

				Order By LSS.FinoAQta



				If @AScaglioni = 0

					Select @Id_LSScaglione = Null

				Else

					If @Id_LSScaglione Is Null 

						Select Top 1

							@Id_LSScaglione = Id_LSScaglione

						From LSScaglione 

						Where Id_LSArticolo = << Format4Spt(oRec.Id_LSArticolo) >>

						Order By FinoAQta Desc



				Select @Id_LSScaglione As Id_LSScaglione

			EndText

			

			oObj = xSqlExec2Obj(cStmt)

			

			nId_LSScaglioneOld = oObj.Id_LSScaglione



			** Test sugli scaglioni

			lDoUpdate = !SafeCompare(nId_LSScaglioneNew, nId_LSScaglioneOld)

			If lDoUpdate And nFlag == 2

				lDoUpdate = (xMessageBox(Thisform.TB_(,'63CE8240-B0C4-4196-A7A8-B578836C5CE9', 'Modificare Prezzi/Sconti/Provvigioni in base allo scaglione?'), MB_ICONQUESTION + MB_YESNO) == IDYES)

				lForce    = lDoUpdate && se l'utente ha risposto SI imposto a .T.

			EndIf

		Else

			lDoUpdate = .T.

			lForce    = !IsEmpty(oRec.Id_LSScaglione)		&& .T. in caso di listini a scaglione

		EndIf	



		If lDoUpdate

			Replace 																;

				PrezzoUnitarioV		With oRec.Prezzo					;

			  	PrezzoAddizionaleV	With oRec.PrezzoAddizionale	;

			  	Id_LSArticolo			With oRec.Id_LSArticolo			;

			  	Id_LSScaglione			With oRec.Id_LSScaglione		;

				In DoRig

		EndIf	

		

	EndIf

EndIf



Return lDoUpdate

ENDPROC

PROCEDURE setdorig_formulae

Local oRec



Select DoRig

Scatter Name oRec Memo



DoRig_Formulae(oRec)



With oRec

	Replace ProvvigioneRiga_1				With .ProvvigioneRiga_1					;

			  FattoreProvv_1					With .FattoreProvv_1						;

			  ProvvigioneRiga_2				With .ProvvigioneRiga_2					;

			  FattoreProvv_2					With .FattoreProvv_2						;

			  ScontoRiga						With .ScontoRiga							;

			  FattoreScontoRiga				With .FattoreScontoRiga					;

			  ScontoAddizionale				With .ScontoAddizionale					;

			  FattoreScontoAddizionale		With .FattoreScontoAddizionale		;

			  ScontoTotale						With .ScontoTotale						;

			  FattoreScontoTotale			With .FattoreScontoTotale				;

			  																						;

			  PrezzoUnitarioV					With .PrezzoUnitarioV					;

			  PrezzoAddizionaleV				With .PrezzoAddizionaleV				;

			  PrezzoUnitarioScontatoV		With .PrezzoUnitarioScontatoV 		;

			  ValProvvigione_1				With .ValProvvigione_1					;

			  ValProvvigione_2				With .ValProvvigione_2					;

			  PrezzoTotaleV					With .PrezzoTotaleV						;

			  PrezzoTotaleE					With .PrezzoTotaleE						;

			  PrezzoResiduoV					With .PrezzoResiduoV						;

			  PrezzoResiduoE					With .PrezzoResiduoE						;

			  PrezzoTotaleMovE				With .PrezzoTotaleMovE					;

	In DoRig

EndWith



ENDPROC

PROCEDURE setdorig_defaults_ca

Lparameters cCd_CGConto



Local oRec



** ----- LICADAPTER

If !oApp.LicInfo.CA_Main

	Return .T.

EndIf



oRec = DoRig_Defaults_CA_2Obj(DoTes.Cd_DO, DoTes.Cd_CF, DoTes.Cd_CFDest, DoRig.Cd_AR, cCd_CGConto)



Replace Cd_CAVda 		With oRec.Cd_CAVda,		;

		  Cd_CACda 		With oRec.Cd_CACda,		;

		  Cd_CAFormula	With oRec.Cd_CAFormula,	;

		  CAPartenza 	With oRec.CAPartenza,	;

		  CADurata 		With oRec.CADurata		;

	In DoRig



ENDPROC

PROCEDURE setdorig_quantita

Lparameters nQtaNew, nQtaOld



Local nDeltaQta, nQtaEvasa, nDeltaQtaEvasa



** Sistemazione quantità evadibile ed evasa

** CODICE ANALOGO NELL'INSERIMENTO DEI LOTTI



*|	nDeltaQta mi serve per aggiornare la qta evadibile nel documento evadente

nDeltaQta = nQtaNew - nQtaOld



** Verifico se la riga ne evade un'altra perchè altrimenti non si può valorizzare la quantità evasa.

If !IsEmpty(DORig.Id_DORIG_Evade) && non si può valorizzare la quantità evasa se non c'è una riga evasa

	** aggiorno la quantità evasa

	** quantità evasa nell'unità di misura della riga evasa

*|	23.07.2025 caso https://dev.azure.com/wkgenya/Arca/_workitems/edit/264325

*|	In caso di evasione devo ricalcolare nQtaEvasa sempre a partire dalla qta in origine

	nQtaEvasa = (DoRig.FattoreToUM1 * nQtaNew) / xDefault(DoRig.DocEvaso_FattoreToUM1, 1)

	If nQtaEvasa > DoRig.DocEvaso_QtaEvadibile + DoRig.QtaEvasa_InOrigine 

		nQtaEvasa = DoRig.DocEvaso_QtaEvadibile + DoRig.QtaEvasa_InOrigine

	EndIf

Else

	nQtaEvasa = 0		&& non c'è una riga evasa quindi quantità evasa = 0 						

EndIf



Replace ;

	Qta 				With nQtaNew, ;

	QtaEvadibile 	With (QtaEvadibile + nDeltaQta), ;

	QtaEvasa 		With nQtaEvasa ;

	In DoRig

	

	



ENDPROC

PROCEDURE ctrls_onvaluechange

Lparameters cControlSource, oControl, xOldValue



Local lForce, lPrezzoChanged, lScontoChanged, lProvvigione1Changed



This.CheckFormule()

This.CheckDoRig_Defaults()



Do Case



****************************************************************************************************



	Case cControlSource == 'cd_ar'



		Local cCd_AR, cDescr, cText, lRet, lRigEvade, lRigNuova



		** Prelevo alcune informazioni sull'articolo: codice, descrizione, stati

		cCd_AR	 = oControl.Value

		cDescr 	 = Eval(oControl.FKAlias + '.Descrizione')

		lRigEvade = !IsEmpty(DoRig.Id_DoRig_Evade)

		

		** BUG 2836

**		lRigNuova = IsEmpty(xOldValue) And IsEmpty(DoRig.Descrizione)

		lRigNuova = IsEmpty(OldVal('Cd_AR', 'DoRig')) And IsEmpty(DoRig.Descrizione)



		** Decido l'azione in base allo stato della riga

		cText = Iif(lRigEvade, 	Thisform.TB_(,'3357789B-4EA2-4D40-AEF2-1F21166D122B', "Attenzione: la riga evade un'altra riga! Riproporre ugualmente tutti i default di riga?"), ;

										Thisform.TB_(,'22E62DAA-148E-4487-9D5B-F2807CC95927', "Attenzione: la riga è già compilata! Riproporre ugualmente tutti i default di riga?"))



		If lRigNuova Or xMessageBox(cText, MB_ICONQUESTION + MB_YESNO) == IDYES



			** Modifico tutti i default della riga perdendo tutti i dati precedentemente scritti

			This.SetDoRig_Defaults(cCd_AR, 0, cDescr)



			** Imposto la commessa di testa, se necessario

			If Empty(DoRig.TipoRigaRif) And !IsEmpty(DoTes.Cd_DoSottocommessa) And !SafeCompare(DoTes.Cd_DoSottocommessa, DoRig.Cd_DoSottocommessa)

				Replace Cd_DoSottocommessa With DoTes.Cd_DoSottocommessa In DoRig



				** Correzione BUG	segnalato da Sacchi					

**					** Aggiorno sconto e le provvigioni in base alla nuova sottocommessa

**					lForce					= .F.

**					lCommessaChanged 		= .T.

**					lPrezzoChanged	  		= .F.	

**					lScontoChanged       = This.SetDORig_Sconto		 (lForce, !lCommessaChanged, !lPrezzoChanged)

**					lProvvigione1Changed = This.SetDORig_Provvigione1(lForce, !lCommessaChanged, !lPrezzoChanged, !lScontoChanged)

**					                       This.SetDORig_Provvigione2(lForce, !lCommessaChanged, !lPrezzoChanged, !lScontoChanged, !lProvvigione1Changed)

			EndIf  



			If !IsNull(oControl.FKAliasRec) And !IsNull(oControl.FKAliasRec.Cd_ARMisura)

				Local oRec, nFatt

				oRec = xSqlExec2Obj("Select UMFatt From ARARMisura Where Cd_AR = " + Format4Spt(oControl.FKAliasRec.Cd_AR) + " And Cd_ARMisura = " + Format4Spt(oControl.FKAliasRec.Cd_ARMisura))

				nFatt = 1

				If Vartype(oRec) = 'O'

					nFatt = xDefault(oRec.UMFatt, 1)

				EndIf

				Replace ;

					Cd_ARMisura With oControl.FKAliasRec.Cd_ARMisura ;

					FattoreToUM1 With nFatt ;

					In DoRig

			EndIf

			

			** Imposto le Note di riga

			

			cNote = xSqlExec2Var(Textmerge('Select Nota From ARNotaDOCAT(<<FormatC4Spt(DOTes.Cd_DO)>>, <<FormatC4Spt(cCd_AR)>>)'))

			Replace NoteRiga With cNote in DoRig



		Else			

			** Modifico solo il codice (questo è implicito) e la descrizione; eventuali anomalie dovute

			** a precedenti valori di alcuni campi (es.  Cd_ARMisura o Cd_ARLotto) non più corretti per

			** il Cd_AR selzionato verrano gestiti dal server al momento del salvataggio

			Replace Descrizione With cDescr In DoRig

		EndIf

		

		** Elimino la distinta custom nel caso appartenga ad una riga descrittiva o nel caso sia mutato il codice articolo

		If !IsEmpty(DoRig.Id_DoDB) And (IsEmpty(cCd_AR) Or !SafeCompare(cCd_AR, xOldValue))

		

			If !SafeCompare(cCd_AR, xOldValue)

				xMessageBox(Thisform.TB_(,'99CAC929-5D82-4E9E-A6B4-D80F57646AEF', "Attenzione: la Distinta Custom associata alla riga documento verrà eliminata !!"), MB_ICONEXCLAMATION)

			EndIf



			Select DoDB

			Locate For Id_DoDB = DoRig.Id_DoDB

			If Found('DoDB')

				Delete In DoDB

				TableUpdate(0, .F., 'DoDB')

				

				Select DoDBAttivita

				Scan For Id_DoDB = DoRig.Id_DoDB

					Delete In DoDBAttivita

					TableUpdate(0, .F., 'DoDBAttivita')	

				EndSCan

				

				Select DoDBMateriale

				Scan For Id_DoDB = DoRig.Id_DoDB

					Delete In DoDBMateriale			

					TableUpdate(0, .F., 'DoDBMateriale')			

				EndScan

			EndIf

			

			Replace Id_DoDB With Null In DoRig



		EndIf

		

****************************************************************************************************



	Case cControlSource == 'descrizione'



		Local cDescr, lRigNuova



		** Prelevo alcune informazioni sull'articolo: descrizione, stato

		cDescr    = oControl.Value

		

		** CASE 07336010

		**lRigNuova = IsEmpty(xOldValue) And IsEmpty(DoRig.Cd_AR)

		lRigNuova = IsEmpty(OldVal('Descrizione', 'DoRig')) And IsEmpty(DoRig.Cd_AR)



		** BUG 4075: se ho incollato una riga copiata, posizionato sul campo Descrizione, mi vengono azzerati tutti i campi. Per questo motivo controllo anche la presenza del campo UM

		If lRigNuova And !IsEmpty(DoRig.Cd_ARMisura)

			lRigNuova = .F.

		EndIf 

				

		If lRigNuova

			** Inserisco tutti i default della riga, che in questo caso (mancando l'articolo) consistono

			** nei campi che non dipendono dal codice articolo

			This.SetDoRig_Defaults(Null, 0, cDescr)

		EndIf



****************************************************************************************************



	Case cControlSource == 'cd_armisura'

	

		Local oRec, cCd_ARMisura, nOldFattUM, nNewFattUM, nQta, nQtaEvadibile, nPrezzoUnitarioV



		cCd_ARMisura = oControl.Value



		oRec = xSqlExec2Obj("Select UMFatt From ARARMisura Where Cd_AR = " + Format4Spt(DoRig.Cd_AR) + " And Cd_ARMisura = " + Format4Spt(cCd_ARMisura))



		If Vartype(oRec) == 'O'

			nOldFattUM = Evl(DoRig.FattoreToUM1, 1.0)

			nNewFattUM = Evl(oRec.UMFatt       , 1.0)

			

			If nNewFattUM != nOldFattUM

				Replace FattoreToUM1 With nNewFattUM In DoRig

				

				If xMessageBox(Thisform.TB_(,'630E17E6-3995-422E-A4C9-55EB85913057', "Modificare la quantità in base al fattore?"), MB_ICONQUESTION + MB_YESNO) == IDYES

					nQta 				= DoRig.Qta 			* nOldFattUM / nNewFattUM

					Replace Qta 			With nQta 				In DoRig

					nQtaEvadibile 	= DoRig.QtaEvadibile * nOldFattUM / nNewFattUM

					Replace QtaEvadibile With nQtaEvadibile 	In DoRig

				EndIf



				If xMessageBox(Thisform.TB_(,'E9BEEDA6-F8E9-4D42-815A-DC8BBFA1A78A', "Modificare il prezzo unitario in base al fattore?"), MB_ICONQUESTION + MB_YESNO) == IDYES

					nPrezzoUnitarioV = DoRig.PrezzoUnitarioV * nNewFattUM / nOldFattUM

					Replace PrezzoUnitarioV With nPrezzoUnitarioV In DoRig



					** aggiorno sconti e provvigioni in base al nuovo prezzo	

					lForce					= .F.			

					lCommessaChanged     = .F.

					lPrezzoChanged       = .T.

					lScontoChanged       = This.SetDORig_Sconto		 (lForce, !lCommessaChanged, !lPrezzoChanged)

					lProvvigione1Changed = This.SetDORig_Provvigione1(lForce, !lCommessaChanged, !lPrezzoChanged, !lScontoChanged)

				      	                 This.SetDORig_Provvigione2(lForce, !lCommessaChanged, !lPrezzoChanged, !lScontoChanged, !lProvvigione1Changed)					

				EndIf

			EndIf

		Else

			Replace FattoreToUM1 With 1.0 In DoRig

		EndIf 

****************************************************************************************************

		

	Case cControlSource == 'qta'



		Local nQtaNew, nQtaOld, nDeltaQta, nQtaEvasa



		nQtaNew = oControl.Value	&& DORig.Qta

		nQtaOld = xOldValue



		** Controllo UM (per righe descrittive)

		If IsEmpty(DoRig.Cd_ARMisura)

			Replace Cd_ARMisura With xSqlExec2Var("Select Cd_ARMisura From ARMisura Where DefaultARMisura = 1 ") In DoRig

		EndIf

		

		** Controllo fattore (per righe descrittive)

		If IsEmpty(DoRig.FattoreToUM1)

			Replace FattoreToUM1 With 1.0 In DoRig

		EndIf



		** ----- LICADAPTER

		** Controllo giacenza		

		If nQtaNew > nQtaOld And oApp.LicInfo.MG_Main

			nQtaNew = This.ControlloGiacenza()

		EndIf

		

		** Imposto la commessa di testa, se necessario (oltre che al cambio di Cd_AR lo faccio anche qua per le evetuali righe senza codice articolo)

		If Empty(DoRig.TipoRigaRif) And !IsEmpty(DoTes.Cd_DoSottocommessa) And !SafeCompare(DoTes.Cd_DoSottocommessa, DoRig.Cd_DoSottocommessa)

			Replace Cd_DoSottocommessa With DoTes.Cd_DoSottocommessa In DoRig

		EndIf  



		** Sistemazione quantità, quantità evasa, evadibile, prezzo, sconto, provvigione ...

		This.SetDoRig_Quantita(nQtaNew, nQtaOld)

		lForce					= .F.

		lCommessaChanged		= .F. 

		lPrezzoChanged       = This.SetDoRig_Prezzo(nQtaNew, nQtaOld, @lForce)	&& lForce: per ricalcolare Sconti e Provv in base allo scaglione...

		lScontoChanged       = This.SetDORig_Sconto		 (lForce, !lCommessaChanged, !lPrezzoChanged)

		lProvvigione1Changed = This.SetDORig_Provvigione1(lForce, !lCommessaChanged, !lPrezzoChanged, !lScontoChanged)

		                       This.SetDORig_Provvigione2(lForce, !lCommessaChanged, !lPrezzoChanged, !lScontoChanged, !lProvvigione1Changed)



****************************************************************************************************



	Case cControlSource == 'prezzounitariov'



		Local lRigDescr



		** Aggiorno aliquota, conto, sconto e le provvigioni in base al nuovo prezzo

		lRigDescr = IsEmpty(DoRig.Cd_AR)



		If lRigDescr And (IsEmpty(DoRig.Cd_Aliquota) Or IsEmpty(DoRig.Cd_CGConto))

			** Questa operazione la faccio solo se la riga è descrittiva

			This.SetDORig_Defaults_AliquotaConto()

			This.SetDoRig_Defaults_CA(DoRig.Cd_CGConto)

		EndIf

		

		lForce					= lRigDescr And IsEmpty(xOldValue) && Forzo in caso di riga descrittiva ed il prezzo è stato modificato dal valore vuoto

		lCommessaChanged		= .F. 

		lPrezzoChanged			= .T.

		lScontoChanged       = This.SetDORig_Sconto		 (lForce, !lCommessaChanged, !lPrezzoChanged)

		lProvvigione1Changed = This.SetDORig_Provvigione1(lForce, !lCommessaChanged, !lPrezzoChanged, !lScontoChanged)

		                       This.SetDORig_Provvigione2(lForce, !lCommessaChanged, !lPrezzoChanged, !lScontoChanged, !lProvvigione1Changed)



****************************************************************************************************



	Case cControlSource == 'scontoriga'



		** Aggiorno le provvigioni in base al nuovo sconto



		lForce			  = .F.

		lCommessaChanged = .F.

		lPrezzoChanged	  = .F.

		lScontoChanged   = .T.    

		lProvvigione1Changed = This.SetDORig_Provvigione1(lForce, !lCommessaChanged, !lPrezzoChanged, !lScontoChanged)

		                       This.SetDORig_Provvigione2(lForce, !lCommessaChanged, !lPrezzoChanged, !lScontoChanged, !lProvvigione1Changed)



****************************************************************************************************



	Case cControlSource == 'provvigioneriga_1'



		** Aggiorno la provvigione 2



		lForce					= .F.

		lCommessaChanged 		= .F.

		lPrezzoChanged	  		= .F.

		lScontoChanged   		= .F.  

		lProvvigione1Changed = .T.		

		This.SetDORig_Provvigione2(lForce, !lCommessaChanged, !lPrezzoChanged, !lScontoChanged, !lProvvigione1Changed)



****************************************************************************************************



	Case cControlSource == 'cd_dosottocommessa'



		** Aggiorno sconto e le provvigioni in base alla nuova sottocommessa



		lForce					= .F.

		lCommessaChanged 		= .T.

		lPrezzoChanged	  		= .F.	

		lScontoChanged       = This.SetDORig_Sconto		 (lForce, !lCommessaChanged, !lPrezzoChanged)

		lProvvigione1Changed = This.SetDORig_Provvigione1(lForce, !lCommessaChanged, !lPrezzoChanged, !lScontoChanged)

		                       This.SetDORig_Provvigione2(lForce, !lCommessaChanged, !lPrezzoChanged, !lScontoChanged, !lProvvigione1Changed)



****************************************************************************************************



	** Se si vuole modificare il prezzo unitario al cambio dell'aliquota IVA, decommentare se righe seguenti:



**		Case cControlSource == 'cd_aliquota' And DoTes.ImportiIvati 

**		

**			** Per i documenti IVATI, al variare dell'aliquota, devo modificare il PrezzoUnitarioV

**			Local nOldAliquota, nNewAliquota, nImponibile

**			

**			nOldAliquota = xSqlExec2Var('Select Aliquota From Aliquota Where Cd_Aliquota = ' + FormatC4Spt(xOldValue))

**			nNewAliquota = oControl.FkRecord.Aliquota

**			IVA_Scorporo(DoRig.PrezzoUnitarioV, nOldAliquota, DoRig.Decimali, @nImponibile)



**			Replace PrezzoUnitarioV With Round(nImponibile * (1+(nNewAliquota/100)), DoRig.Decimali) In DoRig

**			This.SetDoRig_Prezzo(DoRig.Qta, DoRig.Qta, .F.)



****************************************************************************************************



	Case cControlSource == 'cd_aliquota'

	

		AddProperty(This, 'IVA_OnValueChange', .T.)



	Case cControlSource == 'cd_reversecharge'



		AddProperty(This, 'RC_OnValueChange', .T.)



		** viene richiamato nella Setdorig_Defaults_Iva()

		** Thisform.SetRegimeIva('ONEROW+R-RC')



	Case cControlSource == 'cd_aliquota_e'

	

		** Abilito il pick se è presente un codice di esenzione e non è ancora stata selezionata

		Iif(!IsEmpty(DoRig.Cd_Aliquota_e) And IsEmpty(DoRig.DoIntento), Thisform.CmdDoIntento('DORIG'), .T.)

			

		If IsEmpty(DoRig.Cd_Aliquota_e) And !IsEmpty(DoRig.DoIntento)

			Replace DoRig.DoIntento With Null In DoRig

		EndIf

		

		AddProperty(This, 'IVA_OnValueChange', .T.)



	Case cControlSource == 'cd_cgconto'



		** NOTA: Merce-Altro vs Spesa



		** Salvo il valore della configurazione merce/spesa presente nella riga

		Local nContoMerceSpesa

		nContoMerceSpesa = DoRig.ContoMerceSpesa

		

		This.SetDoRig_Defaults_CG(oControl.Value)

		This.SetDoRig_Defaults_CA(oControl.Value)

		This.SetDoRig_Defaults_RR()



		** In base alla configurazione del conto (merce/spesa) metto/tolgo la % sulla riga.

		** Le provvigioni dovrebbero essere calcolate soltanto sul valore della merce. Per non stravolgere i conteggi operiamo

		** sulla proposta della provvigione in modo che i vecchi documenti mantengano gli stessi conteggi ed eventualmente

		** l'utente possa agire sulle righe per includere o meno le righe nel conteggio. I Tipi 1 (Altro), 2 (Merce) sono trattati come merce

		

		If Iif(nContoMerceSpesa != 3, 1, 3) != Iif(DoRig.ContoMerceSpesa != 3, 1, 3)

		

			** Cambio il conto da merce/altro a spesa

			If DoRig.ContoMerceSpesa = 3 And (!IsEmpty(DoRig.ProvvigioneRiga_1) Or !IsEmpty(DoRig.ProvvigioneRiga_2)) And ;

				xMessageBox(Thisform.TB_(,'704B4914-B289-44A6-A684-FB1D2DAED5DD', "Nella riga sono state rilevate delle provvigioni." + Chr(13) + ;

				"In presenza di un conto configurato come spesa non dovrebbero essere conteggiate. Si vuole comunque mantenerle?"), MB_ICONQUESTION + MB_YESNO + MB_DEFBUTTON2) = IDNO

				

				= This.SetDORig_Provvigione1(.T.) And This.SetDORig_Provvigione2(.T.)

				** oControl.Parent.Parent.ColProvvigioneRiga_1.Text1.SetValue('') And oControl.Parent.Parent.ColProvvigioneRiga_2.Text1.SetValue('')



			EndIf

			

			** Cambio il conto da spesa a merce/altro

			If DoRig.ContoMerceSpesa != 3 And (IsEmpty(DoRig.ProvvigioneRiga_1) Or IsEmpty(DoRig.ProvvigioneRiga_2)) And ;

				xMessageBox(Thisform.TB_(,'7F5C3EC2-B539-4287-8400-2CD6302F7A48', "Nella riga non sono state rilevate delle provvigioni." + Chr(13) + ;

				"In presenza di un conto configurato come merce/altro dovrebbero essere conteggiate. Si vuole riproporle?"), MB_ICONQUESTION + MB_YESNO) = IDYES



				= This.SetDORig_Provvigione1(.T.) And This.SetDORig_Provvigione2(.T.)

								

			EndIf



		EndIf

		

****************************************************************************************************



	Case cControlSource == 'cd_mg_a'



		** Cerco se c'è un'ubicazione di default per la coppia Cd_AR, Cd_MG

		Local cUbicaz		

		cUbicaz = xSqlExec2Var('Select Cd_MGUbicazione From ARMGUbicazione Where Cd_AR = ' + FormatC4Spt(DORig.Cd_AR) + ' And Cd_MG = ' + FormatC4Spt(DORig.Cd_MG_A) + ' And DefaultMGUbicazione = 1')

		Replace Cd_MGUbicazione_A With cUbicaz In DORig



****************************************************************************************************

		

	Case cControlSource == 'cd_mg_p'



		** Cerco se c'è un'ubicazione di default per la coppia Cd_AR, Cd_MG

		Local cUbicaz		

		cUbicaz = xSqlExec2Var('Select Cd_MGUbicazione From ARMGUbicazione Where Cd_AR = ' + FormatC4Spt(DORig.Cd_AR) + ' And Cd_MG = ' + FormatC4Spt(DORig.Cd_MG_P) + ' And DefaultMGUbicazione = 1')

		Replace Cd_MGUbicazione_P With cUbicaz In DORig



		Local cCd_MG_P, nQtaNew, nQtaOld

		

		cCd_MG_P = oControl.Value

		

		If !IsEmpty(cCd_MG_P)

			nQtaOld = DoRig.Qta

			nQtaNew = This.ControlloGiacenza()	

			If nQtaNew <> nQtaOld 



				** Sistemazione quantità, quantità evasa, evadibile, prezzo, sconto, provvigione ...

				This.SetDoRig_Quantita(nQtaNew, nQtaOld)



				lForce					= .F. 

				lCommessaChanged 		= .F.

				lPrezzoChanged       = This.SetDoRig_Prezzo(nQtaNew, nQtaOld   )

				lScontoChanged       = This.SetDORig_Sconto		 (lForce, !lCommessaChanged, !lPrezzoChanged)

				lProvvigione1Changed = This.SetDORig_Provvigione1(lForce, !lCommessaChanged, !lPrezzoChanged, !lScontoChanged)

				                       This.SetDORig_Provvigione2(lForce, !lCommessaChanged, !lPrezzoChanged, !lScontoChanged, !lProvvigione1Changed)

			EndIf 

		EndIf

		

****************************************************************************************************



	Case cControlSource == 'omaggio'



		Local nOmaggio, cText

		

		nOmaggio = oControl.Value

		

		If nOmaggio > 1 And (!IsEmpty(DoRig.ProvvigioneRiga_1) Or !IsEmpty(DoRig.ProvvigioneRiga_2))

			Text To cText NoShow Pretext 1+2

				Se non viene eliminata la % di provvigione di riga, all'agente verrà riconosciuta una provvigione anche per questa riga che si è deciso di omaggiare.



				Lasciare in ogni caso le % di provvigione di riga?

			EndText 



			If xMessageBox(Thisform.TB_(,'7543BE3F-92DA-4CC5-A003-D2672697318E', cText), MB_ICONQUESTION + MB_YESNO) != IDYES

				Replace ProvvigioneRiga_1 With '', ProvvigioneRiga_2 With '' In DoRig

			EndIf

		EndIf



	** ----- COAN Section ----- **

	

	Case cControlSource == 'cd_cavda'

	

		Local oRec, lFromDetailForm



		oRec = oControl.FKRecord

		oRec.CADurata = Evl(oRec.CADurata, 1)

		

		lFromDetailForm = (Lower(oControl.Parent.BaseClass) != 'column')



		** Sovrascrivo i defaults se i campi non sono vuoti

		** medesimo comportamento della prima nota



		** Se la formula è vuota la riporto dalla VDA altrimenti chiedo all'utente

		Iif((IsEmpty(DoRig.Cd_CAFormula) And IsEmpty(DoRig.Cd_CACda) And !IsEmpty(oRec.Cd_CAFormula)) Or ;

			( IsEmpty(oRec.Cd_CAFormula) And !IsEmpty(DoRig.Cd_CAFormula) And xMessageBox(Thisform.TB_(,'8EC3C30C-93D0-44FC-8207-5D721C9DC59D', "La voce di analisi selezionata non prevede la formula. Rimuoverla dalla riga?"), MB_YESNO + MB_ICONQUESTION) = IDYES) Or ;

			(!IsEmpty(oRec.Cd_CAFormula) And (!(oRec.Cd_CAFormula == DoRig.Cd_CAFormula) Or !IsEmpty(DoRig.Cd_CACda)) And xMessageBox(Thisform.TB_(,'BE80BDF0-643F-4C1D-835C-E331DF0E2DC3', "Assegnare alla riga la formula associata alla voce di analisi?"), MB_YESNO + MB_ICONQUESTION) = IDYES), ;

			Iif(!lFromDetailForm, oControl.Parent.Parent.ColCd_CAFormula.Text1.SetValue(oRec.Cd_CAFormula), ;

				 oControl.Parent.Parent.txtCd_CAFormula.Field.SetValue(oRec.Cd_CAFormula)), .T.)



		** Aggiornamento campi collegati

			

		If lFromDetailForm



			Iif(IsEmpty(DoRig.CAPartenza) And !IsEmpty(oRec.CAPartenza), oControl.Parent.Parent.cmbCAPartenzaEdit.Field.SetValue(oRec.CAPartenza), .T.)

			Iif(DoRig.CADurata = 1 And oRec.CADurata != 1, oControl.Parent.Parent.TxtCADurataEdit.Field.SetValue(oRec.CADurata), .T.)



		Else

		

			Iif(IsEmpty(DoRig.CAPartenza) And !IsEmpty(oRec.CAPartenza), oControl.Parent.Parent.ColCAPartenza.Cmb_CAofs.SetValue(oRec.CAPartenza), .T.)

			Iif(DoRig.CADurata = 1 And oRec.CADurata != 1, oControl.Parent.Parent.ColCADurata.Text1.SetValue(oRec.CADurata), .T.)



		EndIf



		** Se è vuoto sovrascrivo il codice della formula altrimenti chiedo all'utente

		** If !oControl.IsEmpty() And ;

		** 	((IsEmpty(DORig.Cd_CAFormula) And IsEmpty(DORig.CAPartenza) And DoRig.CADurata <= 1) Or ;

		** 	xMessageBox(Thisform.TB_(,'9BC5760A-FCEB-438F-92F2-A72B60281383', "Proporre i default relativi alla voce di analisi?"), MB_ICONQUESTION + MB_YESNO) == IDYES)



		** 	Iif(lDet, oControl.Parent.Parent.TxtCd_CAFormula.Field.SetValue(oRec.Cd_CAFormula), oControl.Parent.Parent.ColCd_CAFormula.Text1.SetValue(oRec.Cd_CAFormula))

		** 	Iif(lDet, oControl.Parent.Parent.cmbCAPartenzaEdit.Field.SetValue(oRec.CAPartenza), oControl.Parent.Parent.ColCAPartenza.Cmb_CAofs.SetValue(oRec.CAPartenza))

		** 	Iif(lDet, oControl.Parent.Parent.TxtCADurataEdit.Field.SetValue(oRec.CADurata), 		oControl.Parent.Parent.ColCADurata.Text1.SetValue(oRec.CADurata))



		** EndIf



****************************************************************************************************



	Case cControlSource == 'cd_caformula'



		Local lDet



		lDet = (Lower(oControl.Parent.BaseClass) != 'column')

		

		If !IsEmpty(DoRig.Cd_CACda) And !IsEmpty(oControl.Value)

			xMessageBox(Thisform.TB_(,'F74AD14A-9454-40BE-BB20-63D9F4F638FA', "Il centro di analisi verrà rimosso in quanto non compatibile con la presenza della formula."))

			Iif(lDet, oControl.Parent.Parent.txtCd_CACda.Field.SetValue(Null), oControl.Parent.Parent.ColCd_CACda.SpcCACda1.Setvalue(Null))

		EndIf 

		

****************************************************************************************************

	

	Case cControlSource == 'cd_cacda'



		Local lDet



		lDet = (Lower(oControl.Parent.BaseClass) != 'column')

				

		If !IsEmpty(DoRig.Cd_CAFormula) And !IsEmpty(oControl.Value)

			xMessageBox(Thisform.TB_(,'E0447A55-F0A6-4345-8497-364208B6AE0F', "La formula verrà rimossa in quanto non compatibile con la presenza del centro di analisi."))

			Iif(lDet, oControl.Parent.Parent.txtCd_CAFormula.Field.SetValue(Null), oControl.Parent.Parent.ColCd_CAFormula.Text1.Setvalue(Null))

		EndIf 

		

	** ----- RR Section ----- **

	

	Case cControlSource == 'rr_datainizio' Or cControlSource == 'rr_datafine'



		** Soltanto nel caso non sia abilitato il RR

		If !(DoRig.RR_Enabled And Evaluate(ThisForm.PF.pgGenerale.txtCd_DO.Field.FKAlias + '.RR_Enabled')) And ;

			!IsEmpty(oControl.Value) And ;

			(IsEmpty(DoRig.RR_DataInizio) Or IsEmpty(DoRig.RR_DataFine))

				Replace ;

					RR_DataInizio 	With xDefault(DoRig.RR_DataInizio, DoRig.RR_DataFine) ;

					RR_DataFine 	With xDefault(DoRig.RR_DataFine,   DoRig.RR_DataInizio) ;

				In DoRig

		EndIf

		

EndCase



** Testato in Setdorig_default_di(). Serve per saltare il ricalcolo della Di in quanto l'utente interviene sul valore del campo

** Tutti i campi che non concorrono alla gestione della DI

If !InList(Lower(cControlSource), 'cd_ar', 'tipopc', 'qta', 'prezzounitariov', 'scontoriga', 'prezzototalev', 'cd_aliquota', 'cd_reversecharge', 'scontoaddizionale', 'prezzoaddizionalev') And ;

	Type(cControlSource) != 'U' And ;

	!SafeCompare(Evaluate(cControlSource), xOldvalue)

	AddProperty(Thisform.PF.PGGenerale.PF.PGrighe.Cnt.Grid.ColDoIntento.Stdtext1, 'SkipCheck', .T.)

EndIf



** Ricalcolo tutti i campi calcolati già qui, in modo tale che se in sede di pers fosse necessario

** fare delle elaborazioni che si basano anche sui totali di riga sarà sufficiente fare prima un

** Dodefault() e poi eseguire il proprio codice; naturalmente per sicurezza sarà necessario rifare

** questo calcolo in Grid_onValueChange perchè la pers potrebbe aver modificato dei campi che a loro

** volta influenzano i totali di riga



This.SetDoRig_Formulae()



ENDPROC

PROCEDURE ctrls_isvalid

LParameters cControlSource, oControl, lIsChanged, xOldValue



Do Case



		****************************************************************************************************



	Case cControlSource == 'dataconsegna'



		If !IsEmpty(oControl.Value) And oControl.Value < DOTes.DataDoc

			** Il vincolo DATACONSEGNA >= DATA DOC non è valido per le righe prelevate

			If IsEmpty(DoRig.Id_DORig_Evade)

				xMessageBox(Thisform.TB_(,'F6BFE4C4-80CC-4A1F-9D66-9ADF8BBE0989', 'La data consegna non può essere inferiore alla data del documento.'), 16)

				Return .F.

			EndIf 

		EndIf



		****************************************************************************************************



	Case cControlSource == 'qta'



		Local nQtaNew, nQtaOld, nDeltaQta, nQtaEvasa



		nQtaNew = oControl.Value

		nQtaOld = xOldValue



		nDeltaQta = nQtaNew - nQtaOld

		nQtaEvasa = DoRig.QtaEvasa + (DoRig.FattoreToUM1 * nDeltaQta)/xDefault(DoRig.DocEvaso_FattoreToUM1, 1)

		

		If !IsEmpty(DoRig.DocEvaso_Cd_DO)

			If  DoRig.DocEvaso_QtaEvadibile + DoRig.QtaEvasa_InOrigine < nQtaEvasa

				If xMessageBox(Thisform.TB_(,'B54BD1EA-F368-484F-9DE7-3AFBB45DECE1', 'La quantità che si vuole evadere è superiore a quella evadibile.' + CRLF +;

																								'Impostare la quantità evasa al massimo evadibile ?'), MB_ICONQUESTION + MB_YESNO) == IDNO

					Return .F.

				EndIf

			EndIf

		EndIf



		****************************************************************************************************



	Case cControlSource == 'cd_ar'



		** Anche se è vero che questo metodo viene chiamato solo se .IsChanged() è a .T., è anche vero che .IsChanged() dipende dal valore del controllo quando prende il fuoco...

		**	In taluni casi riesco a modificare il campo e poi mi si imposta qualcosa tipo F e non ne vengo più fuori (specie navigando sulla form detail con il fouco sul codice articolo mentre sono in edit...)

		**	Per questo motivo ho messo il codice di cui sotto

		Local cInfo



		If !SafeCompare(oControl.Value, OldVal('Cd_AR', 'DoRig'))



			** In caso venga modificato il codice articolo vado a controllare che la riga non abbia evaso altra riga

			cInfo = This.GetEvadeInfo(DoRig.Id_DoRig_Evade)

			If !IsEmpty(cInfo) And !SafeCompare(oControl.Value, DORig.DocEvaso_Cd_AR) && modificare il secondo RL_INFINITE se si vuole permettere la modifica del codice articolo da documento salvato e non da evasione

				If !QuestionBox(Iif(oControl.FediForm.ModeFromPrelievo == 0, RL_INFINITE, RL_INFINITE), "La riga evade il documento " + cInfo, "modificare il codice articolo")

					oControl.Value = DORig.DocEvaso_Cd_AR 

					Return 0

				EndIf 

			EndIf



			** In caso venga modificato il codice articolo vado a controllare che la riga non sia stata evasa da qualche altro documento

			cInfo = This.GetEvasoDaInfo(DoRig.Id_DoRig)

			If !IsEmpty(cInfo) And !QuestionBox(RL_INFINITE, "La riga è stata evasa dal/dai documenti " + CRLF + cInfo, "proseguire modificando il codice articolo")

				oControl.Value = OldVal('Cd_AR', 'DoRig')

				Return 0

			EndIf



			Thisform.AutoTD_Chk('AR')



		EndIf



		****************************************************************************************************



	Case cControlSource == 'cd_aliquota'



		** Avverto che non è possibile indicare aliquote indetraibili nelle vendite.

		If Evaluate(oControl.FKAlias + '.Indetraibilita') != 0 And DoTes.Clifor = 'C'

			xMessageBox(Thisform.TB_(,'7BD7D7FF-AFDC-48A2-9F3B-1D7F1B63C2A8',	'Non è possibile indicare aliquote indetraibili in movimenti di vendita.' + CRLF + ;

																						'La relativa fatturazione non potrà essere eseguita.'))

			

		EndIf



		** Check per compilazione dutofattura integrativa

		Return Iif(lIsChanged, Thisform.AutoTD_Chk('IVA'), .T.)

		

		****************************************************************************************************



	Case cControlSource == 'cd_aliquota_e'



		** Avverto per eliminazione del codice di esenzione in documento evadente

		If !IsEmpty(xOldValue) And IsEmpty(oControl.Value) And !IsEmpty(DoRig.Id_Dorig_Evade) And !IsNull(Thisform.DoIntento_Evade('R', DoRig.Id_Dorig_Evade)) And ;

			xMessageBox(Thisform.TB_(,'80264B8A-D92C-468E-B1EC-68387D061368', ;

							"La riga è stata evasa da un documento cui è stata applicata lettera d'intento." + CRLF + ;

							"L'eliminazione del codice nel presente documento non effettua alcun aggiornamento del documento evaso." + CRLF + ;

							"Il plafond risulterà in ogni caso utilizzato in base a quanto dichiarato nel documento evaso." + CRLF + CRLF + ;

							"Procedo con la cancellazione del codice?"), MB_ICONQUESTION + MB_YESNO + MB_DEFBUTTON2) == IDNO



			oControl.SetValue(xoldValue)

			Return .F.

		EndIf

				

		****************************************************************************************************

		

	Case cControlSource == 'rr_datainizio' Or cControlSource == 'rr_datafine'



		If lIsChanged

		

			** Data inizio <= Data fine

			If (!IsEmpty(DoRig.RR_DataInizio) And !IsEmpty(DoRig.RR_DataFine)) And DoRig.RR_DataInizio > DoRig.RR_DataFine

				xMessageBox(Thisform.TB_(,'0148F45F-2EE1-4343-B73B-B2211032C0EC', 'La data di inizio del periodo di competenza non può essere posteriore a quella di fine.'))

				Return 0

			EndIf

			

			** Dovrei controllare che le date siano entrambe compilate ma è rischioso farlo in griglia

			** con interattività così spinta, meglio farlo nel querysave.

			

			** Ora controllo la coerenza delle date per RR (Anche per questi le 2 date devono essere compilate)

			If DoRig.RR_Enabled And Evaluate(ThisForm.PF.pgGenerale.txtCd_DO.Field.FKAlias + '.RR_Enabled') And !IsEmpty(DoRig.RR_Cd_CGConto)

				Return RR_ValidateFields(DOTes.DataDoc, DoRig.RR_DataInizio, DoRig.RR_DataFine)

			EndIf



		EndIf



		****************************************************************************************************	



	Case cControlSource == 'tipopc'

	

		If !IsEmpty(oControl.Value) And !InList(oControl.Value, 'P', 'C')

			xMessageBox(Thisform.TB_(,'EB7E55B0-A0A3-4544-B96B-CF1C1D4DDDFE', 'I valori ammessi sono P (Padre) oppure C (Componente).'), 16)

			Return .F.

		EndIf



	Case cControlSource == 'omaggio'		



		Local lReverseCharge, lIvaSplit



		** Attivare per regolare l'applicazione in base al valore della riga sia per cessione che acquisto

		** lReverseCharge	= !IsEmpty(Dorig.Cd_ReverseCharge)

		

		lReverseCharge	= (DoTes.CliFor == 'F' And DoTes.TipoFattura != 0)

		lIvaSplit		= DoTes.IvaSplit

		

		If oControl.Listindex = 3 And (lReverseCharge Or lIvaSplit)

			xMessageBox(Thisform.TB_(,'DF9A0927-2361-45D7-BB63-B3280620DF67', "In caso di inversione contabile o scissione dei pagamenti non è applicabile l'omaggio selezionato."), 16)

			oControl.SetListIndex(2)

			Return .F.

		EndIf



	Case cControlSource == 'id_mgmov_carico'



		Local cSql, oRec

		If !IsEmpty(oControl.Value)

			Text To cSql Noshow Textmerge

				Select DORig.Id_DORig

						,IsOkAR		= Convert(Bit, case when DORig.Cd_AR 	= <<Format4Spt(DORig.Cd_AR)>> then 1 else 0 end)

						,IsDocF		= Convert(Bit, case when Left(DORig.Cd_CF, 1) = 'F' 						then 1 else 0 end)

						,IsCarico	= Convert(Bit, case when DORig.TipoDocumento in ('A', 'B', 'F')		then 1 else 0 end)

					From MGMov

						Left Join DORig On MGMov.Id_MGMov = DORig.Id_MGMov_Carico

					Where  MGMov.Id_MGMov 	= <<Format4Spt(oControl.Value)>> 

			endtext

			Text To cSql Noshow Textmerge

					Select	 MGMov.Id_MGMov

							,IsOkAR		= Convert(Bit, case when MGMov.Cd_AR 	= <<Format4Spt(DORig.Cd_AR)>>				then 1 else 0 end)

							,IsCarico	= Convert(Bit, Case When MgMov.Ini = 1 Or (MgMov.CarA+MgMov.CarP> 0 Or -MgMov.ScaV-MgMov.ScaP>0 )	then 1 else 0 end)

						From MGMov

						Where MGMov.Id_MGMov 	= <<Format4Spt(oControl.Value)>> 

			endtext





			oRec = xSqlExec2Obj(cSql)

			

			If IsNull(oRec)

				xMessageBox(Thisform.TB_(,'C955A314-9F6B-454D-8D34-A67D6E2A54B7'	;

					, 'Id riga non esistente.' + CRLF + CRLF + 'Puoi eseguire una ricerca con F3.'), 16)

				Return .F.

			EndIf 

			If !(oRec.IsOkAR And oRec.Iscarico)

				xMessageBox(Thisform.TB_(,'35E294A7-A205-4F25-B43A-BBAF954DAEC2'	;

					, 'Indicare una riga di carico associato allo stesso articolo sulla riga.' + CRLF + CRLF + 'Puoi eseguire una ricerca con F3.'), 16)

				Return .F.

			Endif	

		Endif

		

EndCase



ENDPROC

PROCEDURE ctrls_when

Lparameters cControlSource, oControl



Do Case



****************************************************************************************************



	Case !(cControlSource == 'cd_ar' Or cControlSource == 'descrizione') And IsEmpty(DoRig.Cd_AR) And IsEmpty(DoRig.Descrizione)

	

		Return .F.	



****************************************************************************************************



	Case cControlSource == 'cd_ar'

		If Thisform.Mode != FEDIMODE_SHOW

			Local lReadOnly

			lReadOnly = !IsEmpty(DoRig.Id_DoRig_Evade) Or Lower(DoRig.TipoRigaRif) == 'r'		&& Attenzione a codice simile in OnRefresh della detail form

			** La riga seguente accetterebbe modifiche di codice per righe evadenti solo una volta che

			** queste fossero state già scritte sul DB e si andasse successivamente in modifica.

			**	lReadOnly = (!IsEmpty(DoRig.Id_DoRig_Evade) And GetFldState(-1, 'DoRig') > '2' )

			If oControl.Thisform = oControl.Fediform

				oControl.Parent.ReadOnly = lReadOnly

			Else

				oControl.ReadOnly = lReadOnly

			EndIf

		EndIf

		Return .T.



****************************************************************************************************



	Case cControlSource == 'cd_mg_p' Or cControlSource == 'cd_mg_a' Or cControlSource == 'cd_mgubicazione_p' Or cControlSource == 'cd_mgubicazione_a'



		Return !IsEmpty(DoRig.Cd_AR)	

	

****************************************************************************************************



	Case cControlSource == 'cd_arlotto'



		Return !IsEmpty(DoRig.Cd_AR)	



****************************************************************************************************



	Case cControlSource == 'qta' Or cControlSource == 'cd_armisura' Or cControlSource == 'fattoretoum1'

	

		** NOTA: questo codice è in relazione con quello nel metodo OnRefresh

		** della form Detail  e con quello nell'Init di questo stesso pgRighe

		** modificabili solo se la riga non è stata evasa

		

		Return (!(Iif(!InList(DoTes.TipoDocumento, 'A', 'F', 'N'), DoRig.Qta != DoRig.QtaEvadibile, .F.)) Or oApp.UserRightLevel >= RL_POWER_USER)



	** ----- COAN Section ----- **



	Case cControlSource == 'cd_caformula'

	

		Return IsEmpty(DoRig.Cd_CACda)



	Case cControlSource == 'cd_cacda'

	

		Return IsEmpty(DoRig.Cd_CAFormula)

		

	** ----- RR Section ----- **



    Case cControlSource == 'rr_datainizio' Or cControlSource == 'rr_datafine'

         

		Return DoRig.RR_Enabled Or DoRig.SezioneBilancio = 'E'



	Case cControlSource == 'rr_cd_cgconto'



		** Non serve testare anche la causale in quanto i campi non sono visibili se non previsto in essa

		Return DoRig.RR_Enabled And Evaluate(ThisForm.PF.pgGenerale.txtCd_DO.Field.FKAlias + '.RR_Enabled')



****************************************************************************************************	



	Case cControlSource == 'tipopc'



		** Non è possibile assegnare il tipo P o C ad una riga con distinta custom

		Return IsEmpty(DoRig.Id_DoDB)



****************************************************************************************************	



	Case cControlSource == 'cd_dosottocommessa'



		** Non è possibile impostare la commessa nelle righe se ne è specificata una nelle teste

		Return IsEmpty(DoTes.Cd_DoSottoCommessa)





	Case cControlSource == 'cd_reversecharge'

	

		Return IsEmpty(Dorig.Cd_RC)





Endcase



ENDPROC

PROCEDURE setdorig_sconto

Lparameters lForce, lCommessaNotChanged, lPrezzoNotChanged



Local oRec, lScontoChanged 



If lForce Or ;

	(!lCommessaNotChanged And (Thisform.Exists_xDORig_Defaults_Sconto_Usr Or Thisform.FormulaScontoUseCommessa)	) Or ;

	(!lPrezzoNotChanged   And  Thisform.Exists_xDORig_Defaults_Sconto_Usr													) 



** Se     la Commessa è cambiata e c'è un TvF personalizzata o la "Commessa" è utilizzata nella Formula

** oppure il Prezzo   è cambiato e c'è un TvF personalizzata



	oRec = DoRig_Defaults_Sconto_2Obj(DoTes.Cd_DO, DoTes.Cd_CF, DoTes.DataDoc, DoRig.DataConsegna, DoTes.Cd_CFDest, DoTes.Cd_Agente_1, DoTes.Cd_Agente_2, DoTes.Cd_PG, DoTes.Cd_LS_1, DoTes.Cd_LS_2, DoTes.Cd_VL, DoTes.Cambio, DoRig.Cd_AR, DORig.Qta, DoRig.Cd_ARMisura, DoRig.FattoreToUM1, DORig.PrezzoUnitarioV, DORig.PrezzoAddizionaleV, DORig.Id_LSArticolo, DORig.Id_LSScaglione, DoRig.Cd_DoSottoCommessa)

	lScontoChanged = !SafeCompare(DoRig.ScontoRiga, oRec.Sconto)

	Replace 	ScontoRiga			With oRec.Sconto					;

				ScontoAddizionale	With oRec.ScontoAddizionale	In DoRig



EndIf 



Return lScontoChanged 

ENDPROC

PROCEDURE setdorig_provvigione1

Lparameters lForce, lCommessaNotChanged, lPrezzoNotChanged, lScontoNotChanged



** In caso di conto nella riga configurato come spesa non propongo la %.

** Il totale delle provvigioni dovrebbe essere calcolato soltanto sul totale merce escludendo tutte le

** eventuali righe del corpo relative a conti di spesa.



Local oRec, lProvvigione1Changed 



If lForce Or ;

	(!lCommessaNotChanged And (Thisform.Exists_xDORig_Defaults_Provvigione1_Usr Or Thisform.FormulaProvvigione1UseCommessa)	) 	Or ;

	(!lPrezzoNotChanged   And  Thisform.Exists_xDORig_Defaults_Provvigione1_Usr															) 	Or ;		

	(!lScontoNotChanged   And (Thisform.Exists_xDORig_Defaults_Provvigione1_Usr Or Thisform.FormulaProvvigione1UseSconto)	) 			



** Se     la Commessa è cambiata e c'è un TvF personalizzata o la "Commessa" è utilizzata nella Formula

** oppure il Prezzo   è cambiato e c'è un TvF personalizzata

** oppure lo Sconto   è cambiato e c'è un TvF personalizzata o lo "Sconto" e utilizzato nella Formula



	oRec = Iif(DoRig.ContoMerceSpesa = 3, Null, DoRig_Defaults_Provvigione1_2Obj(DoTes.Cd_DO, DoTes.Cd_CF, DoTes.DataDoc, DoRig.DataConsegna, DoTes.Cd_CFDest, DoTes.Cd_Agente_1, DoTes.Cd_Agente_2, DoTes.Cd_PG, DoTes.Cd_LS_1, DoTes.Cd_LS_2, DoTes.Cd_VL, DoTes.Cambio, DoRig.Cd_AR, DORig.Qta, DoRig.Cd_ARMisura, DoRig.FattoreToUM1, DORig.PrezzoUnitarioV, DORig.PrezzoAddizionaleV, DORig.Id_LSArticolo, DORig.Id_LSScaglione, DORig.ScontoRiga, DORig.ScontoAddizionale, DoRig.Cd_DoSottoCommessa))

	cVal = Iif(!IsNull(oRec), oRec.Provvigione_1, '')

	lProvvigione1Changed = !SafeCompare(Dorig.ProvvigioneRiga_1, cVal)

	Replace ProvvigioneRiga_1 With cVal In DoRig



EndIf



Return lProvvigione1Changed 

ENDPROC

PROCEDURE setdorig_provvigione2

Lparameters lForce, lCommessaNotChanged, lPrezzoNotChanged, lScontoNotChanged, lProvvigione1NotChanged



** Vedi commento in SetDorig_provvigione_1()



Local oRec



If lForce Or ;

	(!lCommessaNotChanged 		And (Thisform.Exists_xDORig_Defaults_Provvigione2_Usr Or Thisform.FormulaProvvigione2UseCommessa)		) Or ;

	(!lPrezzoNotChanged 			And  Thisform.Exists_xDORig_Defaults_Provvigione2_Usr															 		) Or ;

	(!lScontoNotChanged 			And (Thisform.Exists_xDORig_Defaults_Provvigione2_Usr Or Thisform.FormulaProvvigione2UseSconto)		 	) Or ;

	(!lProvvigione1NotChanged 	And (Thisform.Exists_xDORig_Defaults_Provvigione2_Usr Or Thisform.FormulaProvvigione2UseProvvigione1)	) 		



** Se     la Commessa è cambiata e c'è un TvF personalizzata o la "Commessa" è utilizzata nella Formula

** oppure il Prezzo   è cambiato e c'è un TvF personalizzata

** oppure lo Sconto   è cambiato e c'è un TvF personalizzata o lo "Sconto"       è utilizzato nella Formula

** oppure la Provv1   è cambiata e c'è un TvF personalizzata o la "Provvigione1" è utilizzata nella Formula



	oRec = Iif(DoRig.ContoMerceSpesa = 3, Null, DoRig_Defaults_Provvigione2_2Obj(DoTes.Cd_DO, DoTes.Cd_CF, DoTes.DataDoc, DoRig.DataConsegna, DoTes.Cd_CFDest, DoTes.Cd_Agente_1, DoTes.Cd_Agente_2, DoTes.Cd_PG, DoTes.Cd_LS_1, DoTes.Cd_LS_2, DoTes.Cd_VL, DoTes.Cambio, DoRig.Cd_AR, DORig.Qta, DoRig.Cd_ARMisura, DoRig.FattoreToUM1, DORig.PrezzoUnitarioV, DORig.PrezzoAddizionaleV, DORig.Id_LSArticolo, DORig.Id_LSScaglione, DORig.ScontoRiga, DORig.ScontoAddizionale, DORig.ProvvigioneRiga_1, DoRig.Cd_DoSottoCommessa))

	Replace ProvvigioneRiga_2 With Iif(!IsNull(oRec), oRec.Provvigione_2, '') In DoRig



EndIf

ENDPROC

PROCEDURE setdorig_defaults_aliquotaconto

Local oRec



oRec = DoRig_Defaults_AliquotaConto_2Obj(DoTes.Cd_CF, DoTes.Cd_CFDest, Null, DoTes.Cd_Do)



** Modifica alla funzione DORig_Defaults_AliquotaConto_Std: aggiunto parametro di ritorno @Cd_ReverseCharge (vedi US 323917)

*!*	Replace ;

*!*		Cd_Aliquota		With oRec.Cd_Aliquota ;

*!*		Cd_CGConto		With oRec.Cd_CGConto ;

*!*	In DoRig

*!*	Replace Cd_ReverseCharge With xDefault(Dotes.Cd_ReverseCharge, xSQLExec2Var(Textmerge('Select Cd_ReverseCharge From Aliquota Where Cd_Aliquota = <<FormatC4SPT(oRec.Cd_Aliquota)>>'))) In DoRig



Replace ;

	Cd_Aliquota			With oRec.Cd_Aliquota		;

	Cd_CGConto			With oRec.Cd_CGConto 		;

	Cd_ReverseCharge 	With oRec.Cd_ReverseCharge	;

In DoRig



Replace Cd_ReverseCharge With xDefault(Dotes.Cd_ReverseCharge, DoRig.Cd_ReverseCharge) In DoRig





This.Setdorig_Defaults_CG(oRec.Cd_CGConto)

This.Setdorig_Defaults_DI('DEF')



ENDPROC

PROCEDURE setdorig_postformulae

** Dopo aver ricalcolato tutti i campi calcolati procedo con un postfiltraggio per

** ripulire le righe descrittive  dai valori inopportuni presenti  in alcuni campi



Local oRec



Select DoRig

Scatter Name oRec Memo

With oRec



	If IsEmpty(oRec.Cd_AR)



		Replace Cd_Aliquota			With Iif(IsEmpty(.PrezzoTotaleV) And IsEmpty(.PrezzoUnitarioV), Null, .Cd_Aliquota      )	;

				  Cd_Aliquota_E		With Iif(IsEmpty(.PrezzoTotaleV)	And IsEmpty(.PrezzoUnitarioV), Null, .Cd_Aliquota_E    )	;

				  Cd_Aliquota_R		With Iif(IsEmpty(.PrezzoTotaleV)	And IsEmpty(.PrezzoUnitarioV), Null, .Cd_Aliquota_R    )	;

				  Cd_ReverseCharge	With Iif(IsEmpty(.PrezzoTotaleV)	And IsEmpty(.PrezzoUnitarioV), Null, .Cd_ReverseCharge )	;

				  Cd_CGConto			With Iif(IsEmpty(.PrezzoTotaleV)	And IsEmpty(.PrezzoUnitarioV), Null, .Cd_CGConto       )	;

				  Cd_CAFormula			With Iif(IsEmpty(.PrezzoTotaleV)	And IsEmpty(.PrezzoUnitarioV), Null, .Cd_CAFormula	  	 )	;

				  CAPartenza			With Iif(IsEmpty(.PrezzoTotaleV)	And IsEmpty(.PrezzoUnitarioV), 0	, .CAPartenza	  	    )	;

				  CADurata				With Iif(IsEmpty(.PrezzoTotaleV)	And IsEmpty(.PrezzoUnitarioV), 0	, .CADurata	  		    )	;

				  Cd_CAVda				With Iif(IsEmpty(.PrezzoTotaleV)	And IsEmpty(.PrezzoUnitarioV), Null, .Cd_CAVda			 )	;

				  Cd_CACda				With Iif(IsEmpty(.PrezzoTotaleV)	And IsEmpty(.PrezzoUnitarioV), Null, .Cd_CACda			 )	;

				  RR_DataInizio		With Iif(IsEmpty(.PrezzoTotaleV)	And IsEmpty(.PrezzoUnitarioV), Null, .RR_DataInizio	 )	;

				  RR_DataFine			With Iif(IsEmpty(.PrezzoTotaleV)	And IsEmpty(.PrezzoUnitarioV), Null, .RR_DataFine		 )	;

				  RR_Cd_CGConto		With Iif(IsEmpty(.PrezzoTotaleV)	And IsEmpty(.PrezzoUnitarioV), Null, .RR_Cd_CGConto	 )	;

				  DOIntento				With Iif(IsEmpty(.PrezzoTotaleV)	And IsEmpty(.PrezzoUnitarioV), Null, .DOIntento		    )	;

				  ScontoRiga			With Iif(IsEmpty(.PrezzoUnitarioV) Or IsEmpty(.Qta), ''  , .ScontoRiga    	  )	;

			  	  FattoreScontoRiga	With Iif(IsEmpty(.PrezzoUnitarioV) Or IsEmpty(.Qta), 0   , .FattoreScontoRiga)	;

				  ProvvigioneRiga_1	With Iif(IsEmpty(.PrezzoUnitarioV) Or IsEmpty(.Qta), ''  , .ProvvigioneRiga_1)	;

				  FattoreProvv_1		with Iif(IsEmpty(.PrezzoUnitarioV) Or IsEmpty(.Qta), 0   , .FattoreProvv_1	  )	;

				  ProvvigioneRiga_2	With Iif(IsEmpty(.PrezzoUnitarioV) Or IsEmpty(.Qta), ''  , .ProvvigioneRiga_2)	;

				  FattoreProvv_2		With Iif(IsEmpty(.PrezzoUnitarioV) Or IsEmpty(.Qta), 0   , .FattoreProvv_2	  )	;

				  TipoPC					With ''																									;

				  Cd_MG_P				With Null																								;

				  Cd_MGUbicazione_P 	With Null																								;

				  Cd_MG_A				With Null																								;

				  Cd_MGUbicazione_A	with Null																								;

		In DoRig



	EndIf



	If !IsEmpty(oRec.Cd_AR) And oRec.TipoPC == 'C'



		Replace Cd_Aliquota			With Iif(IsEmpty(.PrezzoTotaleV)							, Null, .Cd_Aliquota      )	;

				  Cd_Aliquota_E		With Iif(IsEmpty(.PrezzoTotaleV)							, Null, .Cd_Aliquota_E    )	;

				  Cd_Aliquota_R		With Iif(IsEmpty(.PrezzoTotaleV)							, Null, .Cd_Aliquota_R    )	;

				  Cd_ReverseCharge	With Iif(IsEmpty(.PrezzoTotaleV)							, Null, .Cd_ReverseCharge )	;

				  Cd_CGConto			With Iif(IsEmpty(.PrezzoTotaleV)							, Null, .Cd_CGConto       )	;

				  Cd_CAFormula			With Iif(IsEmpty(.PrezzoTotaleV)							, Null, .Cd_CAFormula	  )	;

				  CAPartenza			With Iif(IsEmpty(.PrezzoTotaleV)							, 0	, .CAPartenza	  	  )	;

				  CADurata				With Iif(IsEmpty(.PrezzoTotaleV)							, 0	, .CADurata	  		  )	;

				  Cd_CAVda				With Iif(IsEmpty(.PrezzoTotaleV)							, Null, .Cd_CAVda			  )	;

				  Cd_CACda				With Iif(IsEmpty(.PrezzoTotaleV)							, Null, .Cd_CACda			  )	;

				  RR_DataInizio		With Iif(IsEmpty(.PrezzoTotaleV)							, Null, .RR_DataInizio	  )	;

				  RR_DataFine			With Iif(IsEmpty(.PrezzoTotaleV)							, Null, .RR_DataFine		  )	;

				  RR_Cd_CGConto		With Iif(IsEmpty(.PrezzoTotaleV)							, Null, .RR_Cd_CGConto	  )	;

				  DOIntento				With Iif(IsEmpty(.PrezzoTotaleV)							, Null, .DOIntento		  )	;

		In DoRig



	EndIf



EndWith



** Elementi dipendenti dal conto

Iif( IsEmpty(DoRig.Cd_CGConto),  This.Setdorig_Defaults_CG(Null), .T.)



** Propongo il codice di esenzione per dichiarazione intento

This.Setdorig_Defaults_DI('FOR')



** Riporto i dati IVA in base al codice effettivo

This.Setdorig_Defaults_IVA()



ENDPROC

PROCEDURE ctrls_contextmenuproc

Lparameters cControlSource, oControl, nCBMId, xPar1



Do Case



****************************************************************************************************



	Case cControlSource == 'cd_arlotto'



		** La riga deve avere un codice articolo indicato altrimenti non avrebbero senso i lotti, inoltre

		** la riga non deve essere già evasa altrimenti con la ripartizione avrei problemi di riferimento	



		** ----- LICADAPTER

		If !oControl.Enabled 								Or ;

			oControl.ReadOnly 								Or ;

			IsEmpty(DoRig.Cd_AR) 							Or ;

			(DoRig.QtaEvadibile = 0) 						Or ;

			(DoRig.Qta != DoRig.QtaEvadibile) 			Or ;

			!IsEmpty(DoRig.Cd_ARLotto) 					Or ;

			!oApp.LicInfo.MG_Main

			

			Return oControl.ContextMenuProc(nCBMId, xPar1, .T.)

		EndIf



		Do Case



			Case nCBMId == CMM_ADD_ITEMS_TO_CONTEXT_MENU			&& xPar1 oggetto oMenu di classe ShortcutMenu 



				Local oMenu



				oMenu = xPar1

				

				oControl.ContextMenuProc(nCBMId, oMenu, .T.)	



				oMenu.AddMenuBar(Thisform.TM_(,"288053F9-97CE-46C9-8DFC-B5E099625383", "Inserimento Lotti..."), 													, '', MB_EDIT_SRCHSPEC1,,.F.,, "Images\MnuImages\Revert.bmp")

				If !IsEmpty(DoRig.Cd_MG_P)

					oMenu.AddMenuBar(Thisform.TM_(,"EB257BD9-7AB2-4463-AE63-B8D3E34949A1", "Inserimento Lotti Mag.%1!...", Trim(DoRig.Cd_MG_P)),, '', MB_EDIT_SRCHSPEC2,,.F.,, "Images\MnuImages\Revert.bmp")

				EndIf 

				

				Return .T.



			Case nCBMId == CMM_ADD_ITEMS_TO_EDIT_PAD		&& xPar1 Edit Popup Name 

				

				Local cPopupName, cOnSelCmd, cForm



				cPopupName = xPar1

				cForm		  = Thisform.Name

				

				oControl.ContextMenuProc(nCBMId, cPopupName, .T.)	



				DefineBar(MB_EDIT_SRCHSPEC1, cPopupName, [Prompt &cForm..TM_(,"288053F9-97CE-46C9-8DFC-B5E099625383", "Inserimento Lotti...") Picture "Images\MnuImages\Revert.bmp"])

				If !IsEmpty(DoRig.Cd_MG_P)

					DefineBar(MB_EDIT_SRCHSPEC2, cPopupName, [Prompt &cForm..TM_(,"EB257BD9-7AB2-4463-AE63-B8D3E34949A1", "Inserimento Lotti Mag.%1!...", '] + Trim(DoRig.Cd_MG_P) + [') Picture "Images\MnuImages\Revert.bmp"])

				EndIf 



				cOnSelCmd =  Sys(1272, oControl) + '.ContextMenuProc(' + Transform(CMM_PROCESS_CHOICE) + ', Bar())'



				On Selection 	 Bar (MB_EDIT_SRCHSPEC1) Of (cPopupName) &cOnSelCmd

				If !IsEmpty(DoRig.Cd_MG_P)

					On Selection Bar (MB_EDIT_SRCHSPEC2) Of (cPopupName) &cOnSelCmd

				Endif 



				Return .T.

				

			Case nCBMId == CMM_PROCESS_CHOICE



				Local nChoiceId



				nChoiceId  = xPar1



				Do Case

					Case nChoiceId == MB_EDIT_SRCHSPEC1 Or nChoiceId == MB_EDIT_SRCHSPEC2

					

						Local oDo, nRecNo, oRecMG, cCd_MGCausale, oColRett, oItem, lValidate

						Local cCd_AR, cCd_ARLotto, nGiancenza_P, nGiancenza_A

						Local cCd_MG_P, cCd_MGUbicazione_P, cCd_MG_A, cCd_MGUbicazione_A

						Local oForm, nQtaTot, oColRows, lConfirmed, lAbilitaTipoPC

						Local lNotFirst, oRec, nRow

						Local nDeltaQta, nQtaEvasaTot, nQtaRmd, nQtaEvasaRmd

						Local nQta, nQtaEvasa, nQtaEvadibile

						Local oGrid, nId_DoDB_Evade

						Local nRigheOverflow



						oDo = ThisForm.PF.pgGenerale.txtCd_DO.Field.FkRecord		



						cCd_MGCausale  = oDo.Cd_MGCausale	&& causale di magazzino per la rettifica della giacenza

						lAbilitaTipoPC = ThisForm.DE.Preferenza.DOAbilitaTipoPC And oDo.UIAbilitaTipoPC



						** Attenzione: se il documento non ha causale (tipo preventivo) oRecMG sarà un Empty Object

						If (lAbilitaTipoPC And DoRig.TipoPC == 'C')

							oRecMG	= xSqlExec2Obj("Select PCCarQs - PCScaQs + PCRetQs As SignMov_MG_P, ACCarQs - ACScaQs + ACRetQs As SignMov_MG_A From MGCausale Where Cd_MGCausale = " + Format4Spt(cCd_MGCausale), .T.)						

						Else

							oRecMG	= xSqlExec2Obj("Select PPCarQs - PPScaQs + PPRetQs As SignMov_MG_P, APCarQs - APScaQs + APRetQs As SignMov_MG_A From MGCausale Where Cd_MGCausale = " + Format4Spt(cCd_MGCausale), .T.)

						EndIf

						cCd_AR		= DoRig.Cd_AR												

						oColRett		= CreateObject('Collection')

						nRecNo		= Recno('DoRig')		

						lValidate	= (oRecMG.SignMov_MG_P < 0 Or oRecMG.SignMov_MG_A < 0)



						* Preparo la collection delle rettifiche

						Select DoRig

						Scan

						

							If Oldval('Cd_AR','DoRig') = cCd_AR And !IsEmpty(Oldval('Cd_ARLotto','DoRig')) And (!IsEmpty(Oldval('Cd_MG_P','DoRig')) Or !IsEmpty(Oldval('Cd_MG_A','DoRig')))

								cCd_ARLotto			 = 	 Oldval('Cd_ARLotto'			, 'DoRig')

								cCd_MG_P				 = Evl(Oldval('Cd_MG_P'				, 'DoRig'), Null)

								cCd_MGUbicazione_P = Evl(Oldval('Cd_MGUbicazione_P', 'DoRig'), Null)

								cCd_MG_A				 = Evl(Oldval('Cd_MG_A'				, 'DoRig'), Null)

								cCd_MGUbicazione_A = Evl(Oldval('Cd_MGUbicazione_A', 'DoRig'), Null)

								nGiancenza_P		 =   - Oldval('Qta'					, 'DoRig') * Oldval('FattoreToUM1', 'DoRig') * oRecMG.SignMov_MG_P

								nGiancenza_A		 =   - Oldval('Qta'					, 'DoRig') * Oldval('FattoreToUM1', 'DoRig') * oRecMG.SignMov_MG_A



								If !IsEmpty(cCd_MG_P)

									oItem = CreateObject('Empty')

									AddProperty(oItem, 'Cd_ARLotto'		, cCd_ARLotto		  )

									AddProperty(oItem, 'Cd_MG'				, cCd_MG_P			  )

									AddProperty(oItem, 'Cd_MGUbicazione', cCd_MGUbicazione_P)									

									AddProperty(oItem, 'Giacenza'			, nGiancenza_P		  )

									oColRett.Add(oItem)

								EndIf

								If !IsEmpty(cCd_MG_A)

									oItem = CreateObject('Empty')

									AddProperty(oItem, 'Cd_ARLotto'		, cCd_ARLotto		  )

									AddProperty(oItem, 'Cd_MG'				, cCd_MG_A			  )

									AddProperty(oItem, 'Cd_MGUbicazione', cCd_MGUbicazione_A)									

									AddProperty(oItem, 'Giacenza'			, nGiancenza_A		  )

									oColRett.Add(oItem)

								EndIf

								

							EndIf

							

							If DoRig.Cd_AR = cCd_AR And !IsEmpty(DoRig.Cd_ARLotto) And (!IsEmpty(DoRig.Cd_MG_P) Or !IsEmpty(DoRig.Cd_MG_A))

								cCd_ARLotto			 =		 DoRig.Cd_ARLotto

								cCd_MG_P				 = Evl(DoRig.Cd_MG_P				, Null)

								cCd_MGUbicazione_P = Evl(DoRig.Cd_MGUbicazione_P, Null)								

								cCd_MG_A				 = Evl(DoRig.Cd_MG_A				, Null)

								cCd_MGUbicazione_A = Evl(DoRig.Cd_MGUbicazione_A, Null)																

								nGiancenza_P		 = 	 DoRig.Qta * DoRig.FattoreToUM1 * oRecMG.SignMov_MG_P

								nGiancenza_A		 =  	 DoRig.Qta * DoRig.FattoreToUM1 * oRecMG.SignMov_MG_A



								If !IsEmpty(cCd_MG_P)

									oItem = CreateObject('Empty')

									AddProperty(oItem, 'Cd_ARLotto'		, cCd_ARLotto 			)

									AddProperty(oItem, 'Cd_MG'				, cCd_MG_P	  			)

									AddProperty(oItem, 'Cd_MGUbicazione', cCd_MGUbicazione_P	)									

									AddProperty(oItem, 'Giacenza'			, nGiancenza_P			)

									oColRett.Add(oItem)

								EndIf

								If !IsEmpty(cCd_MG_A)

									oItem = CreateObject('Empty')

									AddProperty(oItem, 'Cd_ARLotto'		, cCd_ARLotto 			)

									AddProperty(oItem, 'Cd_MG'				, cCd_MG_A	  			)

									AddProperty(oItem, 'Cd_MGUbicazione', cCd_MGUbicazione_A	)									

									AddProperty(oItem, 'Giacenza'			, nGiancenza_A			)

									oColRett.Add(oItem)

								EndIf



							EndIf

							

						EndScan

						Locate Record (nRecNo)



						** Lancio il wizard di evasione lotti

						oForm = NewObjectWCR7('WzdEvasione', 'Forms\Fedi_ARLotto.vcx', '', DoRig.Cd_AR, DoRig.Qta * DoRig.FattoreToUM1, DoRig.Cd_MG_P, DoRig.Cd_MGUbicazione_P, (nChoiceId == MB_EDIT_SRCHSPEC1), oColRett, lValidate)

						If Vartype(oForm) == 'O'

							oForm.Show(1)



							lConfirmed = oForm.WasConfirmed

							nQtaTot    = oForm.QtaTot

							oColRows	  = oForm.ColRows



							oForm.Release()

						EndIf



						If lConfirmed And Vartype(oColRows) == 'O'



							** Quantità totale ripartita espressa nell'unità di misura della riga documento

							nQtaTot = nQtaTot / Evl(DoRig.FattoreToUM1, 1.0)

							

							** Variazione della quantità

							nDeltaQta = nQtaTot - DoRig.Qta

							

							** Determinazione della QtaEvasa totale a seguito della ripartizione (con aumento della quantità totale)

							** VEDERE IL CODICE IN SetDoRig_Quantita



							If !IsEmpty(DoRig.Id_DoRig_Evade)	&& non si può valorizzare la quantità evasa se non c'è una riga evasa

								** Se la riga evade un'altra riga (è il senso del test precedente) allora calcolo

								** la quantità evasa nell'unità di misura della riga evasa

								nQtaEvasaTot = DoRig.QtaEvasa + (DoRig.FattoreToUM1 * nDeltaQta) / xDefault(DoRig.DocEvaso_FattoreToUM1, 1)

								If nQtaEvasaTot > DoRig.DocEvaso_QtaEvadibile + DoRig.QtaEvasa_InOrigine 

									nQtaEvasaTot = DoRig.DocEvaso_QtaEvadibile + DoRig.QtaEvasa_InOrigine

								EndIf

							Else

								nQtaEvasaTot = 0

							EndIf 



							** Resti a seguito della ripartizione

							nQtaEvasaRmd = nQtaEvasaTot



							** Numero di riga per la numerazione

							nRow = DoRig.Riga



							** Prelevo il record corrente che andrà duplicato

							Select DoRig

							Scatter Memo Name oRec 	

							oRec.Id_DoRig			  = 0 		&&--> indica una riga nuova

							oRec.Cd_ARLotto		  = Null

							oRec.Cd_MG_P			  = Null

							oRec.Cd_MGUbicazione_P = Null							



							oGrid = Thisform.PF.pgGenerale.PF.pgRighe.Cnt.Grid

							

							nRigheOverflow	= 0

							For Each oItem In oColRows



								nQta 				= oItem.Qta / Evl(DoRig.FattoreToUM1, 1.0)

								nQtaEvadibile 	= nQta

								nQtaEvasa 		= nQta / Evl(nQtaTot * nQtaEvasaTot, 1.0) &&--> problema coi decimali arrotondati!!! (vedi sotto)



								If !lNotFirst &&--> è la riga originale

									lNotFirst = .T.

									

									** Impostazione della quantità

									Replace Qta With nQta, QtaEvadibile With nQtaEvadibile, QtaEvasa With nQtaEvasa In DoRig

								Else

									** Rinumerazione delle righe successive

									nRow = nRow + 1

									Replace Riga With Riga + 1 For Riga >= nRow In DoRig

									oRec.Riga = nRow		

									

									** Impostazione della quantità

									oRec.Qta 			= nQta

									oRec.QtaEvadibile = nQtaEvadibile

									oRec.QtaEvasa 		= nQtaEvasa

									

									** Inserimento della nuova riga

									oGrid.RowAppend()

		

									Select DoRig

									Gather Name oRec Memo		

									

									** Duplicazione della distinta se è necessario

									If !IsEmpty(DoRig.Id_DoRig_Evade)

										If IsEmpty(nId_DoDB_Evade)

											xSqlExec("Select Id_DoDB From DoRig Where Id_DoRig = " + Format4Spt(DoRig.Id_DoRig_Evade), "Tmp_IdDoDB")

											nId_DoDB_Evade = Nevl(Tmp_IdDoDB.Id_DoDB, -1)

										Endif 

										If nId_DoDB_Evade <= 0 

											If !IsEmpty(DoRig.Id_DoDB)

												Thisform.DuplicateCustomDB(DoRig.Id_DoDB, .T.)

											Endif 

										Else 

											If !SafeCompare(Id_DoDB, Tmp_IdDoDB.Id_DoDB)

												Replace Id_DoDB With Tmp_IdDoDB.Id_DoDB In DoRig

											Endif 

										Endif

									Else

										If !IsEmpty(DoRig.Id_DoDB)

											Thisform.DuplicateCustomDB(DoRig.Id_DoDB, .T.)

										Endif

									Endif	



								EndIf 

									

								** Scateno l'OnValueChange per far agire la cascata di controlli e impostazioni associati alla quantità

								oGrid.ColQta.stdText1.SetValue(nQta, .T.)

								

								** Impostazione del magazzino

								If !SafeCompare(DoRig.Cd_MG_P, oItem.Cd_MG)

									oGrid.ColCd_MG_P.stdText1.SetValue(oItem.Cd_MG)

								EndIf 

								

								** Impostazione dell'ubicazione

								If !SafeCompare(DoRig.Cd_MGUbicazione_P, oItem.Cd_MGUbicazione)

									oGrid.ColCd_MGUbicazione_P.stdText1.SetValue(oItem.Cd_MGUbicazione)

								EndIf 



								** Impostazione del lotto

								If !SafeCompare(DoRig.Cd_ARLotto, oItem.Cd_ARLotto)

									oGrid.ColCd_ARLotto.stdText1.SetValue(oItem.Cd_ARLotto)

								EndIf 



								** Aggiornamento dei resti					

							*|	23.07.2025 caso https://dev.azure.com/wkgenya/Arca/_workitems/edit/264325

							*|	La qtaevasa viene calcolata in modo errato se la qta sulla riga è stata modificata in modo

							*|	che sia maggiore della qtaevadibile del documento evaso.

								If nQtaEvasaRmd - DoRig.QtaEvasa < 0	

*|										Questo è il caso in cui sto evadendo più della quantità sulla riga originale. Se è una sola

*|										riga, Arca accetta questa anomalia, se abbiamo più righe e una delle righe va in "overflow",

*|										la successiva va in errore con il messaggio: la qtaevasa non può essere negativa!!

									If nRigheOverflow = 0

										** Al primo overflow imposto la qtaevasa in modo che non vada in errore

										nRigheOverflow = nRigheOverflow + 1

										** e mi salvo che è il primo overflow, ovvero che ho già impostato la corretta qtaevasa, 

										** mi serve per evitare di azzerare erronemente qtaevasa e id_dorig_evade a fine ciclo.

										Replace QtaEvasa With nQtaEvasaRmd In DoRig

										nQtaEvasaRmd = nQtaEvasaRmd - DoRig.QtaEvasa

									Else

										** Ma dal secondo azzero la QtaEvasa

										nQtaEvasaRmd 		= nQtaEvasaRmd - DoRig.QtaEvasa

										** Avendo già allineato la qtaevasa, mi salvo che non è il primo overflow

										** ho già correttamente impostato i valori di qtaevasa.

										nRigheOverflow = nRigheOverflow + 1

										Replace QtaEvasa With 0 In DoRig

									Endif

								Else

									nQtaEvasaRmd = nQtaEvasaRmd - DoRig.QtaEvasa								

								endif

								If DORig.QtaEvasa = 0

*|									Se non metto a null il campo Id_DoRig_Evade, nella griglia apparirà con il colore

*|									delle righe che evadono, anche avendo la qtaevasa a zero e questo non è corretto.

									Replace Id_DoRig_Evade With Null In DORig

								Endif

								

							EndFor

					

							** Sistemazione decimali arrotondati sull'ultima riga scritta

							*|	23.07.2025 caso https://dev.azure.com/wkgenya/Arca/_workitems/edit/264325

							*|	In caso di evasione devo ricalcolare nQtaEvasa sempre a partire dalla qta in origine

							If nRigheOverflow > 1	&& ho già correttamente impostato i valori di qtaevasa

								Replace QtaEvasa With 0, Id_DoRig_Evade With Null In DoRig

							Else

							 	Replace QtaEvasa With QtaEvasa + nQtaEvasaRmd In DoRig

							Endif							

							Select DoRig

							Skip + 1 && necessario per far agire l'indice sul numero di riga

							Locate Record (nRecNo)	&& necessario per il refresh della griglia altrimenti non considera correttamente l'ordine delle righe

							

							oGrid.Refresh() 

							

						EndIf

						

						Return .T.

						

					Otherwise

						Return oControl.ContextMenuProc(nCBMId, nChoiceId, .T.)

				EndCase



		EndCase



		Return



****************************************************************************************************



	Case cControlSource == 'tipopc'



		If !oControl.Enabled 								Or ;

			 oControl.ReadOnly 								Or ;

			 IsEmpty(DoRig.Cd_AR) 							Or ;

			!IsEmpty(DoRig.Id_DoDB)

			

			Return oControl.ContextMenuProc(nCBMId, xPar1, .T.)

		EndIf



		Do Case



			Case nCBMId == CMM_ADD_ITEMS_TO_CONTEXT_MENU			&& xPar1 oggetto oMenu di classe ShortcutMenu 



				Local oMenu, lBrwSpc1, lBrwSpc2, lBrwSpc3, lBrwSpc4



				oMenu = xPar1

				

				oControl.ContextMenuProc(nCBMId, oMenu, .T.)	

				

				** Nota: utilizzo i #define di tipo SRCHSPEC? anche se si tratta di comandi e non di ricerche

				

				lBrwSpc1 = IsEmpty(DoRig.TipoPC)

				lBrwSpc2 = IsEmpty(DoRig.TipoPC)

				lBrwSpc3 = (DoRig.TipoPC == 'P')

				lBrwSpc4 = (DoRig.TipoPC == 'P')

				

				oMenu.AddMenuBar('\-',,, MB_EDIT_SEP_SEARCH2)	

									

**				oMenu.AddMenuBar(Thisform.TM_(,"DBC6DAD3-F38B-42CD-A479-BD99CFBA13BE", "Converti %1! in lista materiali..."	, Alltrim(DoRig.Cd_AR)),, 'Key Alt+0, "Ctrl+F5"', MB_EDIT_SRCHSPEC1,, !lBrwSpc1,, "Images\MnuImages\Elenco.bmp")

				oMenu.AddMenuBar(Thisform.TM_(,"03ACF2CF-0D75-4EA7-A40C-E0BD08C86D60", "Converti %1! in lista P/C..."			, Alltrim(DoRig.Cd_AR)),, 'Key Alt+0, "Ctrl+F6"', MB_EDIT_SRCHSPEC2,, !lBrwSpc2,, "Images\MnuImages\Elenco.bmp")				

				oMenu.AddMenuBar(Thisform.TM_(,"79FF6481-1429-4212-87E5-FE05DC0346AD", "Ricalcola prezzo di %1!..."				, Alltrim(DoRig.Cd_AR)),, 'Key Alt+0, "Ctrl+F7"', MB_EDIT_SRCHSPEC3,, !lBrwSpc3,, "Images\MnuImages\Money.bmp" )

				oMenu.AddMenuBar(Thisform.TM_(,"20731203-B1BE-4F7C-94A4-874141DF8F1B", "Ricalcola prezzo di tutte le righe P...")						  ,, 'Key Alt+0, "Ctrl+F8"', MB_EDIT_SRCHSPEC4,, !lBrwSpc4,, "Images\MnuImages\Money.bmp" )				

				

				Return .T.



			Case nCBMId == CMM_ADD_ITEMS_TO_EDIT_PAD		&& xPar1 Edit Popup Name 



				Local cPopupName, cOnSelCmd, cBrwSpc1, cBrwSpc2, cBrwSpc3, cBrwSpc4, cForm



				cPopupName = xPar1

				cForm		  = Thisform.Name



				oControl.ContextMenuProc(nCBMId, cPopupName, .T.)	



				** Nota: utilizzo i #define di tipo SRCHSPEC? anche se si tratta di comandi e non di ricerche



				cBrwSpc1 = Tran(!IsEmpty(DoRig.TipoPC))

				cBrwSpc2 = Tran(!IsEmpty(DoRig.TipoPC))

				cBrwSpc3 = Tran(!(DoRig.TipoPC == 'P'))

				cBrwSpc4	= Tran(!(DoRig.TipoPC == 'P'))



				Define Bar (MB_EDIT_SEP_SEARCH2) Of (cPopupName) Prompt "\-"



**				DefineBar(MB_EDIT_SRCHSPEC1, cPopupName, [Prompt &cForm..TM_(,"DBC6DAD3-F38B-42CD-A479-BD99CFBA13BE", "Converti %1! in lista materiali..."		, '] + Alltrim(DoRig.Cd_AR) + [') Key Alt+0, "Ctrl+F5" Picture "Images\MnuImages\Elenco.bmp" Skip For &cBrwSpc1])

				DefineBar(MB_EDIT_SRCHSPEC2, cPopupName, [Prompt &cForm..TM_(,"03ACF2CF-0D75-4EA7-A40C-E0BD08C86D60", "Converti %1! in lista P/C ..."     		, '] + Alltrim(DoRig.Cd_AR) + [') Key Alt+0, "Ctrl+F6" Picture "Images\MnuImages\Elenco.bmp" Skip For &cBrwSpc2])

				DefineBar(MB_EDIT_SRCHSPEC3, cPopupName, [Prompt &cForm..TM_(,"79FF6481-1429-4212-87E5-FE05DC0346AD", "Ricalcola prezzo di %1! ..."					, '] + Alltrim(DoRig.Cd_AR) + [') Key Alt+0, "Ctrl+F7" Picture "Images\MnuImages\Money.bmp"  Skip For &cBrwSpc3])

				DefineBar(MB_EDIT_SRCHSPEC4, cPopupName, [Prompt &cForm..TM_(,"20731203-B1BE-4F7C-94A4-874141DF8F1B", "Ricalcola prezzo di tutte le righe P ..."										  ) Key Alt+0, "Ctrl+F8" Picture "Images\MnuImages\Money.bmp"  Skip For &cBrwSpc4])



				cOnSelCmd =  Sys(1272, oControl) + '.ContextMenuProc(' + Transform(CMM_PROCESS_CHOICE) + ', Bar())'



**				On Selection 	 Bar (MB_EDIT_SRCHSPEC1) Of (cPopupName) &cOnSelCmd

				On Selection 	 Bar (MB_EDIT_SRCHSPEC2) Of (cPopupName) &cOnSelCmd				

				On Selection 	 Bar (MB_EDIT_SRCHSPEC3) Of (cPopupName) &cOnSelCmd				

				On Selection 	 Bar (MB_EDIT_SRCHSPEC4) Of (cPopupName) &cOnSelCmd				

				

				Return .T.



			Case nCBMId == CMM_PROCESS_CHOICE



				Local nChoiceId



				nChoiceId  = xPar1



				Do Case

**						Case nChoiceId == MB_EDIT_SRCHSPEC1

**							Thisform.CmdDoDBConverti(, 1, .T.)

**							Return .T.



					Case nChoiceId == MB_EDIT_SRCHSPEC2



						Thisform.CmdDoDBConverti(, 2, .T.)

						

						Return .T.						



					Case InList(nChoiceId, MB_EDIT_SRCHSPEC3, MB_EDIT_SRCHSPEC4)



						Local nRec1, nRec2, nTotaleV, cMsg, cFor

					

						Select DoRig

						nRec1 = Recno()

		

						If nChoiceId = MB_EDIT_SRCHSPEC3

							cMsg = 'Ricalcolo prezzo di ' +  Alltrim(DoRig.Cd_AR) + ' in corso ...'

							cFor = ' And Recno() = ' + Tran(Recno())

						EndIf

						If nChoiceId = MB_EDIT_SRCHSPEC4

							cMsg = 'Ricalcolo prezzo di tutte le righe P...'

							cFor = ''

						EndIf



						Wait cMsg Windows NoWait

						Thisform.LockScreen = .T.

						

						This.Grid.ColTipoPC.Text1.ValidSkippedForFormDeactivation = .F.

						

						** Il prezzo totale è decurtato degli sconti per cui per calcolare

						** a ritroso il prezzo unitario del padre devo aggiungerlo. Bisogna anche tenere conto

						** del prezzo addizionale



						Scan For (TipoPC = 'P' &cFor)

							nRec2 = Recno()

							Skip +1

							nTotaleV 	= 0

							Do While !Eof() And (TipoPC = 'C')

								nTotaleV = nTotaleV + PrezzoTotaleV

								Skip +1

							EndDo

							Locate Record nRec2



							Replace ;

								PrezzoUnitarioV 	 With xRound(nTotaleV / Evl(PercStrEvalCD(ScontoRiga) * PercStrEvalCD(ScontoAddizionale), 1) / Evl(DoRig.Qta, 1.0), DoRig.DecimaliPrzUn) ;

								PrezzoAddizionaleV With 0



							This.SetDoRig_Formulae()

							This.SetDoRig_PostFormulae()

						EndScan

						

						Locate Record nRec1



						This.Grid.Refresh()

			

						Wait Clear

						Thisform.LockScreen = .F.



						Return .F.

						

					Otherwise

						Return oControl.ContextMenuProc(nCBMId, nChoiceId, .T.)

				EndCase



		EndCase



		Return



****************************************************************************************************



	Case cControlSource == 'prezzounitariov'

	

		If !oControl.Enabled 								Or ;

			 oControl.ReadOnly

			

			Return oControl.ContextMenuProc(nCBMId, xPar1, .T.)

		EndIf



		Do Case



			Case nCBMId == CMM_ADD_ITEMS_TO_CONTEXT_MENU



				Local oMenu, lBrwSpc0



				oMenu = xPar1

				

				oControl.ContextMenuProc(nCBMId, oMenu, .T.)	



				lBrwSpc0 = PemStatus(oControl, 'BrwSpc0', 5) = .F. Or oControl.BrwSpc0

					

				** Ricerca Prezzi

				oMenu.AddMenuBar('\-',,,MB_EDIT_SEP_SEARCH)

				oMenu.AddMenuBar(Thisform.TM_(,"FAE1A07E-775B-4DA1-8C01-B5279DDAF50C", "Ricerca \<Prezzi..."),,'Key Alt+0, "F3"',	MB_EDIT_SRCHSPEC0,,!lBrwSpc0,, "Images\MnuImages\Find3.bmp")

				

				** Scorporo				

				If oControl.Enabled And !oControl.ReadOnly And !DoTes.ImportiIvati

					oMenu.AddMenuBar(Thisform.TM_(,"F3079D9A-64EC-4484-899F-DE545FCDD007", "Scorporo prezzo"),, 'Key Alt+0, "s"', MB_EDIT_SRCHSPEC1,,.F.,, "Images\MnuImages\Meno1.bmp")

				EndIf



				** Submenu Dati previdenza

				Thisform.RA_Previdenza_Check(0, , oMenu)



				Return .T.



			Case nCBMId == CMM_ADD_ITEMS_TO_EDIT_PAD

				

				Local cPopupName, cOnSelCmd, cBrwSpc0, cForm



				cPopupName = xPar1

				cForm		  = Thisform.Name



				oControl.ContextMenuProc(nCBMId, cPopupName, .T.)	



				cBrwSpc0 = Transform(PemStatus(oControl, 'BrwSpc0', 5) = .F. Or oControl.BrwSpc0)



				DefineBar(MB_EDIT_SEP_SEARCH, cPopupName, [Prompt "\-"])

				DefineBar(MB_EDIT_SRCHSPEC0 , cPopupName, [Prompt &cForm..TM_(,"9E21C6C2-2B3A-48DD-910E-3871FFC03A67", "Ricerca \<Prezzi...") Key Alt+0, "F3" Picture "Images\MnuImages\Find3.bmp" Skip For !&cBrwSpc0])



				cOnSelCmd = Sys(1272, oControl) + '.ContextMenuProc(' + Transform(CMM_PROCESS_CHOICE) + ', Bar())'



				On Selection Bar (MB_EDIT_SRCHSPEC0) Of (cPopupName) &cOnSelCmd



				If oControl.Enabled And !oControl.ReadOnly

					DefineBar(MB_EDIT_SRCHSPEC1,  cPopupName, [Prompt &cForm..TM_(,"C5B2F324-E104-4C93-9203-F1C37D2D8AE4", "Scorporo prezzo") Key Alt+0, "s" Picture "Images\MnuImages\Meno1.bmp"])

					On Selection 	Bar (MB_EDIT_SRCHSPEC1) Of (cPopupName) &cOnSelCmd

				EndIf



				Return .T.

				

			Case nCBMId == CMM_PROCESS_CHOICE						&& xPar1 nChoiceId - Torna .T. nel caso nChoiceId sia stato processato



				Local nChoiceId, oSrchForm



				nChoiceId  = xPar1



				Do Case

					Case nChoiceId == MB_EDIT_SRCHSPEC0

						If oControl.Enabled And !oControl.ReadOnly 

							Local oParam 

							oParam = CreateObject('Empty')

							

							AddProperty(oParam, 	'Cd_AR', 					DORig.Cd_AR)

							AddProperty(oParam, 	'Cd_CF', 					DOTes.Cd_CF)

							AddProperty(oParam, 	'Cd_CFDest', 				DOTes.Cd_CFDest)

							AddProperty(oParam, 	'Cd_DO', 					DOTes.Cd_DO)

							AddProperty(oParam, 	'DataDoc', 					DOTes.DataDoc)

							AddProperty(oParam, 	'DataConsegna', 			DORig.DataConsegna)					

							AddProperty(oParam, 	'Qta', 						DORig.Qta)

							AddProperty(oParam, 	'Cd_Agente_1', 			DOTes.Cd_Agente_1)

							AddProperty(oParam, 	'Cd_Agente_2', 			DOTes.Cd_Agente_2)

							AddProperty(oParam, 	'Cd_PG', 					DOTes.Cd_PG)

							AddProperty(oParam, 	'Cd_VL', 					DOTes.Cd_VL)

							AddProperty(oParam, 	'Cambio', 					DOTes.Cambio)

							AddProperty(oParam, 	'Id_DOTes', 				DOTes.Id_DOTes)

							AddProperty(oParam, 	'Cd_LS_1', 					DOTes.Cd_LS_1)

							AddProperty(oParam, 	'Cd_LS_2', 					DOTes.Cd_LS_2)

							AddProperty(oParam, 	'Cd_DOSottoCommessa', 	DORig.Cd_DOSottoCommessa)



							AddProperty(oParam, 	'PrezzoV', 					DORig.PrezzoUnitarioV)

							AddProperty(oParam, 	'Sconto', 					DORig.ScontoRiga)

							AddProperty(oParam, 	'Provvigione1', 			DORig.ProvvigioneRiga_1)

							AddProperty(oParam, 	'Provvigione2', 			DORig.ProvvigioneRiga_2)



							AddProperty(oParam, 	'Cd_ARMisura', 			DORig.Cd_ARMisura)

							AddProperty(oParam, 	'FattoreToUm1', 			DORig.FattoreToUm1)

							AddProperty(oParam, 	'DecimaliPrzUn', 			DORig.DecimaliPrzUn)



							** DOCIVATI **

							AddProperty(oParam, 	'Cd_Aliquota', 			DORig.Cd_Aliquota)



							AddProperty(oControl,	'SrcParameters', 		oParam)



							oControl.FKSelect 		= "" 



							oSrchForm = RunFastSrcForm(ThisForm, oControl, 'fedi_doccommon', 'fastsrcform_arprezzo')

							oControl.AddProperty('BrwSpc0', Vartype(oSrchForm) == 'O')

							If oControl.BrwSpc0

								oSrchForm.Show(1)

							EndIf	

							

							** BUG 3233 - Conclusa la ricerca ridò il fuoco al controllo corrente (questo soprattutto quando è aperta la form Detail)

							oControl.SetFocus()

							

						EndIf 

						Return .T.

						

					Case nChoiceId == MB_EDIT_SRCHSPEC1



						If oControl.Enabled And !oControl.ReadOnly And !Empty(DoRig.Cd_Aliquota)

							Local nPrezzoUnitarioV, nPrezzoAddizionaleV



							nPerc = xSQLExec2Var('Select Aliquota From Aliquota Where Cd_Aliquota = ' + Format4SPT(DoRig.Cd_Aliquota))

							**nPrezzoUnitarioV = (oControl.Value * 100 / (100 + Nvl(nPerc, 0)))

							IVA_Scorporo(oControl.Value, nPerc, DoRig.DecimaliPrzUn, @nPrezzoUnitarioV)

							oControl.SetValue(Round(nPrezzoUnitarioV, DoRig.DecimaliPrzUn))

							If ThisForm.PF.pgGenerale.txtCd_DO.Field.FkRecord.IvaPerRiga

								nPrezzoAddizionaleV = Round(nPrezzoUnitarioV - oControl.Value, DoRig.DecimaliPrzUn + 2) &&--> come trigger DoRig

								Replace PrezzoAddizionaleV With nPrezzoAddizionaleV In DoRig

							EndIf

						EndIf

						

					Otherwise

						Return DoDefault(nCBMId, nChoiceId)

				EndCase

					



		EndCase



		Return



****************************************************************************************************



	Case cControlSource == 'cd_aliquota_e'



		If (Thisform.Mode = FEDIMODE_SHOW And IsEmpty(Dorig.DoIntento) And IsNull(Thisform.DoIntento_Evade('R', DoRig.Id_Dorig_Evade))) Or ;

			(!IsEmpty(Dorig.Cd_Aliquota_e) And !xSQLExec2Bit(Textmerge("Exists(Select * From Aliquota Where Cd_Aliquota = <<FormatC4SPT(Dorig.Cd_Aliquota_e)>> And Cd_TipoIva In ('181C', '182', '18B2', '192'))")))

			Return oControl.ContextMenuProc(nCBMId, xPar1, .T.)

		EndIf



		Do Case



			Case nCBMId == CMM_ADD_ITEMS_TO_CONTEXT_MENU			&& xPar1 oggetto oMenu di classe ShortcutMenu 



				Local oMenu



				oMenu = xPar1

				

				oControl.ContextMenuProc(nCBMId, oMenu, .T.)	

				

				** Nota: utilizzo i #define di tipo SRCHSPEC? anche se si tratta di comandi e non di ricerche

				

				oMenu.AddMenuBar('\-',,, MB_EDIT_SEP_SEARCH2)	

				oMenu.AddMenuBar(Thisform.TM_(,"20731203-B1BE-4F7C-94A4-874141DF8F1B", "Dichiarazioni Intento"),, 'Key Alt+0, "F6"', MB_EDIT_SRCHSPEC0,, .F.,, "Images\MnuImages\Partitario.bmp")				



				Return .T.



			Case nCBMId == CMM_ADD_ITEMS_TO_EDIT_PAD		&& xPar1 Edit Popup Name 



				Local cPopupName, cOnSelCmd



				cPopupName = xPar1

				cForm		  = Thisform.Name



				oControl.ContextMenuProc(nCBMId, cPopupName, .T.)	



				** Nota: utilizzo i #define di tipo SRCHSPEC? anche se si tratta di comandi e non di ricerche



				Define Bar (MB_EDIT_SEP_SEARCH2) Of (cPopupName) Prompt "\-"

				DefineBar(MB_EDIT_SRCHSPEC0, cPopupName, [Prompt &cForm..TM_(,"20731203-B1BE-4F7C-94A4-874141DF8F1B", "Dichiarazioni Intento") Key Alt+0, "F6" Picture "Images\MnuImages\Partitario.bmp"])

				cOnSelCmd = Sys(1272, oControl) + '.ContextMenuProc(' + Transform(CMM_PROCESS_CHOICE) + ', Bar())'

				On Selection Bar (MB_EDIT_SRCHSPEC0) Of (cPopupName) &cOnSelCmd				

				

				Return .T.



			Case nCBMId == CMM_PROCESS_CHOICE



				Local nChoiceId



				nChoiceId  = xPar1



				Do Case



					Case nChoiceId == MB_EDIT_SRCHSPEC0



						Thisform.CmdDoIntento('DORIG')

						Return .T.						



					Otherwise

						Return oControl.ContextMenuProc(nCBMId, nChoiceId, .T.)

				EndCase



		EndCase



		Return



	Case cControlSource == 'id_mgmov_carico'



		If !oControl.Enabled 								Or ;

			 oControl.ReadOnly			

			Return oControl.ContextMenuProc(nCBMId, xPar1, .T.)

		EndIf



		Do Case



			Case nCBMId == CMM_ADD_ITEMS_TO_CONTEXT_MENU



				Local oMenu, lBrwSpc0



				oMenu = xPar1

				

				oControl.ContextMenuProc(nCBMId, oMenu, .T.)	



				lBrwSpc0 = PemStatus(oControl, 'BrwSpc0', 5) = .F. Or oControl.BrwSpc0

					

				** Ricerca rigo di carico

				oMenu.AddMenuBar('\-',,,MB_EDIT_SEP_SEARCH)

				oMenu.AddMenuBar(Thisform.TM_(,"FAE1A07E-775B-4DA1-8C01-B5279DDAF50C", "\<Ricerca riga carico..."),,'Key Alt+0, "F3"',	MB_EDIT_SRCHSPEC0,,!lBrwSpc0,, "Images\MnuImages\Find3.bmp")			

				oMenu.AddMenuBar(Thisform.TM_(,"F3079D9A-64EC-4484-899F-DE545FCDD007", "\<Cancella riferimento"),, 'Key Alt+0, "c"', MB_EDIT_SRCHSPEC1,,.F.,, "Images\MnuImages\Meno1.bmp")



				Return .T.



			Case nCBMId == CMM_ADD_ITEMS_TO_EDIT_PAD

				

				Local cPopupName, cOnSelCmd, cBrwSpc0, cForm



				cPopupName = xPar1

				cForm		  = Thisform.Name



				oControl.ContextMenuProc(nCBMId, cPopupName, .T.)	



				cBrwSpc0 = Transform(PemStatus(oControl, 'BrwSpc0', 5) = .F. Or oControl.BrwSpc0)



				DefineBar(MB_EDIT_SEP_SEARCH, cPopupName, [Prompt "\-"])

				DefineBar(MB_EDIT_SRCHSPEC0 , cPopupName, [Prompt &cForm..TM_(,"9E21C6C2-2B3A-48DD-910E-3871FFC03A67", "\<Ricerca riga carico...") Key Alt+0, "F3" Picture "Images\MnuImages\Find3.bmp" Skip For !&cBrwSpc0])

				cOnSelCmd = Sys(1272, oControl) + '.ContextMenuProc(' + Transform(CMM_PROCESS_CHOICE) + ', Bar())'

				On Selection Bar (MB_EDIT_SRCHSPEC0) Of (cPopupName) &cOnSelCmd



				DefineBar(MB_EDIT_SRCHSPEC1,  cPopupName, [Prompt &cForm..TM_(,"C5B2F324-E104-4C93-9203-F1C37D2D8AE4", "\<Cancella riferimento") Key Alt+0, "c" Picture "Images\MnuImages\Meno1.bmp"])

				On Selection 	Bar (MB_EDIT_SRCHSPEC1) Of (cPopupName) &cOnSelCmd



					Return .T.

				

			Case nCBMId == CMM_PROCESS_CHOICE						&& xPar1 nChoiceId - Torna .T. nel caso nChoiceId sia stato processato



				Local nChoiceId, oSrchForm



				nChoiceId  = xPar1



				Do Case

					Case nChoiceId == MB_EDIT_SRCHSPEC0

						If oControl.Enabled And !oControl.ReadOnly 



							Local oForm, nId_MGMov_Carico

							oForm = NewObjectWCR3('Id_MGMov_Carico_Pick', 'Forms\Fedi_DocCommon.vcx', '', DORig.Cd_AR, DOTes.DataDoc, DORig.Id_MGMov_Carico)

													

							If Vartype(oForm) = 'O'

								oForm.Show(1)



								If oForm.WasConfirmed  

										nId_MGMov_Carico = oForm.Id_MGMov_Carico

										If !IsEmpty(nId_MGMov_Carico)

											oControl.SetValue(nId_MGMov_Carico)

											Replace Id_MGMov_Carico With nId_MGMov_Carico In DoRig

										Endif

								Endif

								

								oForm.Release()

								oForm = Null

							Endif  

												

							** BUG 3233 - Conclusa la ricerca ridò il fuoco al controllo corrente (questo soprattutto quando è aperta la form Detail)

							oControl.SetFocus()

							

						EndIf 

						Return .T.

						

					Case nChoiceId == MB_EDIT_SRCHSPEC1



						If oControl.Enabled And !oControl.ReadOnly And !IsEmpty(DoRig.Id_MGMov_Carico)

								Replace Id_MGMov_Carico With Null In DoRig

								oControl.Refresh()

						EndIf

						

					Otherwise

						Return DoDefault(nCBMId, nChoiceId)

				EndCase

					



		EndCase



		Return

EndCase



							



ENDPROC

PROCEDURE grid_contextmenuproc

Lparameters oControl, lFromDetailForm, nCBMId, xPar1



Local cControlSource, oCol, vRet, cPFix



** Le date trattate con DateTimeLikeDate hanno come cs 'This.DataSource' ed il vero CS in TrueControlSource

cPFix = Iif(PemStatus(oControl, 'DateTimeLikeDate', 5) And oControl.DateTimeLikeDate And !Empty(oControl.TrueControlSource), 'True', '')

cControlSource = AllTrim(Lower(oControl.&cPfix.ControlSource))



If Empty(cControlSource)		

	** Quando vengono invocati i metodi .SaveRecordSource e RestoreRecordSource della griglia, si 

	** scatenano le Valid e si riesce ad arrivare in punti come questo con il ControlSource vuoto

	Return

Else

	** Se il ControlSource è composto ricavo solo il nome del campo

	cControlSource = Iif(At('.', cControlSource) > 0, JustExt(cControlSource), cControlSource)

EndIf



** Creazione dei riferimenti ausiliari

AddProperty(oControl, 'Thisform', Iif(lFromDetailForm, This.RowDetailForm, Thisform))

AddProperty(oControl, 'Fediform', Thisform                                          )



** Rigiro la chiamata

vRet = This.Ctrls_ContextMenuProc(cControlSource, oControl, nCBMId, xPar1)



** Rimozione dei riferimenti ausiliari

oControl.Thisform = Null

oControl.Fediform = Null



** Refresh: avendo cambiato il cursore è bene rinfrescare i controlli collegati

If lFromDetailForm

	** Devo scatenare il refresh di tutta la pagina

	This.RowDetailForm.PF.pgGenerale.Refresh()

Else

	** Devo scatenare il refresh controllo per controllo

	For Each oCol In This.Grid.Columns

		oCol.Controls[2].Refresh()

	EndFor

EndIf



Return vRet



ENDPROC

PROCEDURE setdorig_defaults_rr

Lparameters cAlias



Local oDef



** ----- LICADAPTER

If !oApp.LicInfo.CG_Main

	Return .T.

EndIf



cAlias = xDefault(cAlias, 'DORig')

oDef 	 = RR_GetDefaults_DO(DoTes.Cd_DO, &cAlias..Cd_CGConto, DOTes.DataDoc)



** Se il conto è vuoto lo prendo dalle impostazioni

If oDef.RR_Enabled And IsEmpty(oDef.RR_Cd_CGConto)

	oDef.RR_Cd_CGConto = RR_GetConto(Null, DOTes.DataDoc, &cAlias..RR_DataInizio, &cAlias..RR_DataFine, Null, Null)

EndIf



Replace ;

	RR_Enabled		With oDef.RR_Enabled		;

	RR_Cd_CGConto 	With oDef.RR_Cd_CGConto	;

	RR_DataInizio 	With oDef.RR_DataInizio ;

	RR_DataFine   	With oDef.RR_DataFine   ;

	In (cAlias)





ENDPROC

PROCEDURE grid_click

Lparameters oControl, lFromDetailForm



Local cControlSource, oCol, vRet, cPFix



** Le date trattate con DateTimeLikeDate hanno come cs 'This.DataSource' ed il vero CS in TrueControlSource

cPFix = Iif(PemStatus(oControl, 'DateTimeLikeDate', 5) And oControl.DateTimeLikeDate And !Empty(oControl.TrueControlSource), 'True', '')

cControlSource = AllTrim(Lower(oControl.&cPfix.ControlSource))



If Empty(cControlSource)		

	** Quando vengono invocati i metodi .SaveRecordSource e RestoreRecordSource della griglia, si 

	** scatenano le Valid e si riesce ad arrivare in punti come questo con il ControlSource vuoto

	Return

Else

	** Se il ControlSource è composto ricavo solo il nome del campo

	cControlSource = Iif(At('.', cControlSource) > 0, JustExt(cControlSource), cControlSource)

EndIf



** Creazione dei riferimenti ausiliari

AddProperty(oControl, 'Thisform', Iif(lFromDetailForm, This.RowDetailForm, Thisform))

AddProperty(oControl, 'Fediform', Thisform                                          )



** Rigiro la chiamata

vRet = This.Ctrls_Click(cControlSource, oControl)



** Rimozione dei riferimenti ausiliari

oControl.Thisform = Null

oControl.Fediform = Null



** Refresh: avendo cambiato il cursore è bene rinfrescare i controlli collegati

If lFromDetailForm

	** Devo scatenare il refresh di tutta la pagina

	This.RowDetailForm.PF.pgGenerale.Refresh()

Else

	** Devo scatenare il refresh controllo per controllo

	For Each oCol In This.Grid.Columns

		oCol.Controls[2].Refresh()

	EndFor

EndIf



Return vRet



ENDPROC

PROCEDURE ctrls_click

Lparameters cControlSource, oControl



Do Case



****************************************************************************************************	



	Case cControlSource == 'id_dodb'



		** Non è possibile associare una distinta custom ad una riga di tipo P o C

		If !IsEmpty(DoRig.TipoPC)

			xMessageBox(Thisform.TB_(,'B7BF9C7E-DE21-473C-B84F-F2928D97DE37', 'Non è possibile assegnare una distinta custom ad una riga di tipo P (Padre) oppure C (Componente).'), 16)		

		Else

			Thisform.cmdDoDBEdit(oControl.Thisform)

		EndIf



****************************************************************************************************	



EndCase





ENDPROC

PROCEDURE grid_onvaluepick

Lparameters oControl, lFromDetailForm, nSearchFormType, xValue4Value, oSelectedRec



Local cControlSource, oCol, vRet, cPFix



** Le date trattate con DateTimeLikeDate hanno come cs 'This.DataSource' ed il vero CS in TrueControlSource

cPFix = Iif(PemStatus(oControl, 'DateTimeLikeDate', 5) And oControl.DateTimeLikeDate And !Empty(oControl.TrueControlSource), 'True', '')

cControlSource = AllTrim(Lower(oControl.&cPfix.ControlSource))



If Empty(cControlSource)		

	** Quando vengono invocati i metodi .SaveRecordSource e RestoreRecordSource della griglia, si 

	** scatenano le Valid e si riesce ad arrivare in punti come questo con il ControlSource vuoto

	Return

Else

	** Se il ControlSource è composto ricavo solo il nome del campo

	cControlSource = Iif(At('.', cControlSource) > 0, JustExt(cControlSource), cControlSource)

EndIf



** Creazione dei riferimenti ausiliari

AddProperty(oControl, 'Thisform', Iif(lFromDetailForm, This.RowDetailForm, Thisform))

AddProperty(oControl, 'Fediform', Thisform                                          )



** Rigiro la chiamata

vRet = This.Ctrls_OnValuePick(cControlSource, oControl, nSearchFormType, xValue4Value, oSelectedRec)



** Rimozione dei riferimenti ausiliari

oControl.Thisform = Null

oControl.Fediform = Null



** Refresh: avendo cambiato il cursore è bene rinfrescare i controlli collegati

If lFromDetailForm

	** Devo scatenare il refresh di tutta la pagina

	This.RowDetailForm.PF.pgGenerale.Refresh()

Else

	** Devo scatenare il refresh controllo per controllo

	For Each oCol In This.Grid.Columns

		oCol.Controls[2].Refresh()

	EndFor

EndIf



Return vRet



ENDPROC

PROCEDURE ctrls_onvaluepick

LParameters cControlSource, oControl, nSearchFormType, xValue4Value, oSelectedRec



Local lFromDetailForm, lRet



lFromDetailForm = (oControl.Thisform != oControl.Fediform)



Do Case



****************************************************************************************************



	Case cControlSource == 'cd_mgubicazione_p'

		lRet = .T.

		If nSearchFormType = BROWSE_MODE_SPECIAL

		* Con ubicazioni preferenziali è possibile selenzionare da BROWSE_MODE_SPECIAL righe che non soddisfano il valid del campo. Controllo.

			If lFromDetailForm

				lRet = lRet And oControl.Parent.Parent.txtCd_MG_P.Field .SetValue(oSelectedRec.Cd_MG			 )

				If !lRet

					xMessageBox(Thisform.TB_(,'9EA75D82-F71D-4748-AA26-37F254FB3452',[Non è possibile impostare il codice magazzino ']+Alltrim(Nevl(oSelectedRec.Cd_MG,''))+[' nella riga del documento.]),64)

				Else

					lRet = lRet And oControl.Parent.Parent.txtCd_MG_P.Field1.SetValue(oSelectedRec.Cd_MGUbicazione)

					If !lRet

						xMessageBox(Thisform.TB_(,'C87A1BA3-61E2-43CF-BC0D-6D2C415CFE67',[Non è possibile impostare il codice ubicazione ']+Alltrim(Nevl(oSelectedRec.Cd_MGUbicazione,''))+[' nella riga del documento.]),64)

					EndIf

				EndIf

			Else

				lRet = lRet And oControl.Parent.Parent.ColCd_MG_P			  .StdText1.SetValue(oSelectedRec.Cd_MG			 )

				If !lRet

					xMessageBox(Thisform.TB_(,'F018D6D3-77EB-4C79-B710-58AABA97DF92',[Non è possibile impostare il codice magazzino ']+Alltrim(Nevl(oSelectedRec.Cd_MG,''))+[' nella riga del documento.]),64)

				Else

					lRet = lRet And oControl.Parent.Parent.ColCd_MGUbicazione_P.StdText1.SetValue(oSelectedRec.Cd_MGUbicazione)

					If !lRet

						xMessageBox(Thisform.TB_(,'8BC1E979-25C3-48C4-97AF-EEF59A50D8C3',[Non è possibile impostare il codice ubicazione ']+Alltrim(Nevl(oSelectedRec.Cd_MGUbicazione,''))+[' nella riga del documento.]),64)

					EndIf

				EndIf

			EndIf

		EndIf

		Return lRet And oControl.OnValuePick(nSearchFormType, xValue4Value, oSelectedRec, .T.)

	

	Case cControlSource == 'cd_mgubicazione_a'

		lRet = .T.

		If nSearchFormType = BROWSE_MODE_SPECIAL

		* Con ubicazioni preferenziali è possibile selenzionare da BROWSE_MODE_SPECIAL righe che non soddisfano il valid del campo. Controllo.

			If lFromDetailForm

				lRet = lRet And oControl.Parent.Parent.txtCd_MG_A.Field .SetValue(oSelectedRec.Cd_MG			 )

				If !lRet

					xMessageBox(Thisform.TB_(,'713E1251-8B70-471F-B87F-59CBF5307430',[Non è possibile impostare il codice magazzino ']+Alltrim(Nevl(oSelectedRec.Cd_MG,''))+[' nella riga del documento.]),64)

				Else

					lRet = lRet And oControl.Parent.Parent.txtCd_MG_A.Field1.SetValue(oSelectedRec.Cd_MGUbicazione)

					If !lRet

						xMessageBox(Thisform.TB_(,'24878AE0-03BE-4E62-AA60-5974790B5C2E',[Non è possibile impostare il codice ubicazione ']+Alltrim(Nevl(oSelectedRec.Cd_MGUbicazione,''))+[' nella riga del documento.]),64)

					EndIf

				EndIf

			Else

				lRet = lRet And oControl.Parent.Parent.ColCd_MG_A			  .StdText1.SetValue(oSelectedRec.Cd_MG			 )

				If !lRet

					xMessageBox(Thisform.TB_(,'528E5552-E021-423E-A13E-4BAF7EB9ADE5',[Non è possibile impostare il codice magazzino ']+Alltrim(Nevl(oSelectedRec.Cd_MG,''))+[' nella riga del documento.]),64)

				Else

					lRet = lRet And oControl.Parent.Parent.ColCd_MGUbicazione_A.StdText1.SetValue(oSelectedRec.Cd_MGUbicazione)

					If !lRet

						xMessageBox(Thisform.TB_(,'D80B9353-E6E5-4B20-B220-8CA429D8E8E7',[Non è possibile impostare il codice ubicazione ']+Alltrim(Nevl(oSelectedRec.Cd_MGUbicazione,''))+[' nella riga del documento.]),64)

					EndIf

				EndIf

			EndIf

		EndIf

		Return lRet And oControl.OnValuePick(nSearchFormType, xValue4Value, oSelectedRec, .T.)		

	

	Case cControlSource == 'cd_arlotto'		

		lRet = .T.

		If nSearchFormType = BROWSE_MODE_SPECIAL

		* Con ubicazioni preferenziali è possibile selenzionare da BROWSE_MODE_SPECIAL righe che non soddisfano il valid del campo. Controllo.

			If lFromDetailForm

				If oControl.Parent.Parent.txtCd_MG_P.Visible And (!IsNull(DORig.Cd_MG_P) Or IsNull(DORig.Cd_MG_A))

					lRet = lRet And oControl.Parent.Parent.txtCd_MG_P.Field .SetValue(oSelectedRec.Cd_MG			 )

					If !lRet

						xMessageBox(Thisform.TB_(,'81662619-FE09-403B-A46C-C35D5656BE44',[Non è possibile impostare il codice magazzino ']+Alltrim(Nevl(oSelectedRec.Cd_MG,''))+[' nella riga del documento.]),64)

					Else

						lRet = lRet And oControl.Parent.Parent.txtCd_MG_P.Field1.SetValue(oSelectedRec.Cd_MGUbicazione)

						If !lRet

							xMessageBox(Thisform.TB_(,'5E22EF7F-0764-4BEC-8F4A-35D837B0B861',[Non è possibile impostare il codice ubicazione ']+Alltrim(Nevl(oSelectedRec.Cd_MGUbicazione,''))+[' nella riga del documento.]),64)

						EndIf

					Endif

				Else

					If oControl.Parent.Parent.txtCd_MG_A.Visible

						lRet = lRet And oControl.Parent.Parent.txtCd_MG_A.Field .SetValue(oSelectedRec.Cd_MG			 )

						If !lRet

							xMessageBox(Thisform.TB_(,'546053B9-0C4E-42CD-B563-7FC6D3127A7D',[Non è possibile impostare il codice magazzino ']+Alltrim(Nevl(oSelectedRec.Cd_MG,''))+[' nella riga del documento.]),64)

						Else

							lRet = lRet And oControl.Parent.Parent.txtCd_MG_A.Field1.SetValue(oSelectedRec.Cd_MGUbicazione)			

							If !lRet

								xMessageBox(Thisform.TB_(,'BAC2B26A-CA57-4B82-A6A8-942BB74039A2',[Non è possibile impostare il codice ubicazione ']+Alltrim(Nevl(oSelectedRec.Cd_MGUbicazione,''))+[' nella riga del documento.]),64)

							EndIf

						EndIf

					EndIf 

				EndIf 

			Else

				If oControl.Parent.Parent.ColCd_MG_P.Visible And (!IsNull(DORig.Cd_MG_P) Or IsNull(DORig.Cd_MG_A))

					lRet = lRet And oControl.Parent.Parent.ColCd_MG_P			  .StdText1.SetValue(oSelectedRec.Cd_MG			 )

					If !lRet

						xMessageBox(Thisform.TB_(,'1BA38D38-74EA-4142-856C-FD9F5939D083',[Non è possibile impostare il codice magazzino ']+Alltrim(Nevl(oSelectedRec.Cd_MG,''))+[' nella riga del documento.]),64)

					Else

						lRet = lRet And oControl.Parent.Parent.ColCd_MGUbicazione_P.StdText1.SetValue(oSelectedRec.Cd_MGUbicazione)

						If !lRet

							xMessageBox(Thisform.TB_(,'0A43E8BF-B4B5-4D46-BA65-462B78F1AC09',[Non è possibile impostare il codice ubicazione ']+Alltrim(Nevl(oSelectedRec.Cd_MGUbicazione,''))+[' nella riga del documento.]),64)

						EndIf

					EndIf

				Else

					If oControl.Parent.Parent.ColCd_MG_A.Visible

						lRet = lRet And oControl.Parent.Parent.ColCd_MG_A			  .StdText1.SetValue(oSelectedRec.Cd_MG			 )

						If !lRet

							xMessageBox(Thisform.TB_(,'03A5359A-190F-4B8C-A0F6-1EDF840BF21C',[Non è possibile impostare il codice magazzino ']+Alltrim(Nevl(oSelectedRec.Cd_MG,''))+[' nella riga del documento.]),64)

						Else

							lRet = lRet And oControl.Parent.Parent.ColCd_MGUbicazione_A.StdText1.SetValue(oSelectedRec.Cd_MGUbicazione)			

							If !lRet

								xMessageBox(Thisform.TB_(,'96EBEE58-8CFA-4DB0-976C-5F50EBB63148',[Non è possibile impostare il codice ubicazione ']+Alltrim(Nevl(oSelectedRec.Cd_MGUbicazione,''))+[' nella riga del documento.]),64)

							EndIf

						EndIf

					EndIf 

				EndIf 

			EndIf

		EndIf

		Return lRet And oControl.OnValuePick(nSearchFormType, xValue4Value, oSelectedRec, .T.)		



	Case cControlSource == 'prezzounitariov'



		oControl.FKSelect = ''		&&--> Necessario altrimenti procede con la validazione



		lRet = oControl.SetValue(xValue4Value)

		If lFromDetailForm

			lRet = lRet And oControl.Parent.Parent.txtPrezzoAddizionaleV.Field.SetValue(oSelectedRec.PrezzoAddizionaleV)

			If oSelectedRec.Riporta

				lRet = lRet And oControl.Parent.Parent.txtScontoRiga		  .Field.SetValue(oSelectedRec.Sconto				)

				lRet = lRet And oControl.Parent.Parent.txtProvvigioneRiga_1.Field.SetValue(oSelectedRec.Provvigione1		)

				lRet = lRet And oControl.Parent.Parent.txtProvvigioneRiga_2.Field.SetValue(oSelectedRec.Provvigione2		)

				lRet = lRet And oControl.Parent.Parent.txtScontoAddizionale.Field.SetValue(oSelectedRec.ScontoAddizionale)

			EndIf

		Else

			Replace PrezzoAddizionaleV With oSelectedRec.PrezzoAddizionaleV In DoRig

			If oSelectedRec.Riporta

				lRet = lRet And oControl.Parent.Parent.ColScontoRiga		  .Text1.SetValue(oSelectedRec.Sconto		 )

				lRet = lRet And oControl.Parent.Parent.ColProvvigioneRiga_1.Text1.SetValue(oSelectedRec.Provvigione1)

				lRet = lRet And oControl.Parent.Parent.ColProvvigioneRiga_2.Text1.SetValue(oSelectedRec.Provvigione2)

				Replace ScontoAddizionale With oSelectedRec.ScontoAddizionale In DoRig

			EndIf

		EndIf

		Replace Id_LSArticolo With oSelectedRec.Id_LSArticolo, Id_LSScaglione With oSelectedRec.Id_LSScaglione In DoRig

		Return lRet And oControl.OnValuePick(nSearchFormType, xValue4Value, oSelectedRec, .T.)



****************************************************************************************************



EndCase











ENDPROC

PROCEDURE setdorig_commessa

**	If Empty(DoRig.TipoRigaRif)

**		If !IsEmpty(DoTes.Cd_DoSottocommessa)

**			Replace Cd_DoSottocommessa With DoTes.Cd_DoSottocommessa In DoRig

**			Replace Cd_Sottocommessa   With DoTes.Cd_DoSottocommessa In DoRigSpesa

**			

**			This.SetDORig_Sconto()		

**			This.SetDORig_Provvigione1()

**			This.SetDORig_Provvigione2()

**		EndIf 

**	EndIf 

ENDPROC

PROCEDURE setdorig_defaults_cg

LParameters cCd_CGConto



** Mi serve valorizzato anche il campo sezionebilancio dai conti per l'utilizzo in Ctrls_When().

** Funziona anche con par null/blank ma per non perdere tempo imposto direttamente null

Local oRec



oRec = Iif(IsEmpty(cCd_CGConto), Null, xSQLExec2Obj(Textmerge('Select SezioneBilancio, ContoMerceSpesa From CGConto Where Cd_CGConto = <<FormatC4SPT(cCd_CGConto)>>')))



Replace ;

	SezioneBilancio	With Iif(IsNull(oRec), '', oRec.SezioneBilancio) ;

	ContoMerceSpesa 	With Iif(IsNull(oRec), 0,  oRec.ContoMerceSpesa) ;

In DoRig



ENDPROC

PROCEDURE checkformule

** Verifico le formule per ricavare Sconti e Provvigioni



Local cStmt, oRet



If !PemStatus(Thisform, 'Formula_Cd_DO', 5) Or Thisform.Formula_Cd_DO != DoTes.Cd_DO		&& lo eseguo solo al cambio del tipo documento



	Text To cStmt Textmerge NoShow

		Select	

			FormulaScontoUseCommessa				= Case When PatIndex('%Commessa%'	 , ScontoRiga) 		 > 0 Then 1 Else 0 End, 

			FormulaProvvigione1UseCommessa		= Case When PatIndex('%Commessa%'	 , ProvvigioneRiga_1) > 0 Then 1 Else 0 End, 

			FormulaProvvigione1UseSconto			= Case When PatIndex('%Sconto%'		 , ProvvigioneRiga_1) > 0 Then 1 Else 0 End, 		

			FormulaProvvigione2UseCommessa		= Case When PatIndex('%Commessa%'	 , ProvvigioneRiga_2) > 0 Then 1 Else 0 End,

			FormulaProvvigione2UseSconto			= Case When PatIndex('%Sconto%'		 , ProvvigioneRiga_2) > 0 Then 1 Else 0 End,

			FormulaProvvigione2UseProvvigione1	= Case When PatIndex('%Provvigione1%', ProvvigioneRiga_2) > 0 Then 1 Else 0 End

		From 

			DO 

		Where 

			Cd_DO = <<FormatC4Spt(DoTes.Cd_DO)>>

	EndText 

	oRet = xSqlExec2Obj(cStmt)



	Thisform.AddProperty('Formula_Cd_DO'							, DoTes.Cd_DO)

	Thisform.AddProperty('FormulaScontoUseCommessa'				, oRet.FormulaScontoUseCommessa 				= 1)

	Thisform.AddProperty('FormulaProvvigione1UseCommessa'		, oRet.FormulaProvvigione1UseCommessa 		= 1)

	Thisform.AddProperty('FormulaProvvigione1UseSconto'		, oRet.FormulaProvvigione1UseSconto 		= 1)

	Thisform.AddProperty('FormulaProvvigione2UseCommessa'		, oRet.FormulaProvvigione2UseCommessa 		= 1)

	Thisform.AddProperty('FormulaProvvigione2UseSconto'		, oRet.FormulaProvvigione2UseSconto 		= 1)

	Thisform.AddProperty('FormulaProvvigione2UseProvvigione1', oRet.FormulaProvvigione2UseProvvigione1 = 1)



EndIf 

ENDPROC

PROCEDURE checkdorig_defaults

** Verifico presenza di Tvf personalizzate



Local oRet



If !PemStatus(Thisform, 'Exists_xDORig_Defaults_Sconto_Usr', 5)	&& lo eseguo solo una volta



	Text To cStmt TextMerge NoShow

		Select xDORig_Defaults_Sconto_Usr       = OBJECT_ID('xDORig_Defaults_Sconto_Usr'),

				 xDORig_Defaults_Provvigione1_Usr = OBJECT_ID('xDORig_Defaults_Provvigione1_Usr'),

				 xDORig_Defaults_Provvigione2_Usr = OBJECT_ID('xDORig_Defaults_Provvigione2_Usr') 

	EndText 

	oRet = xSqlExec2Obj(cStmt)



	Thisform.AddProperty('Exists_xDORig_Defaults_Sconto_Usr'			, !IsNull(oRet.xDORig_Defaults_Sconto_Usr))

	Thisform.AddProperty('Exists_xDORig_Defaults_Provvigione1_Usr' , !IsNull(oRet.xDORig_Defaults_Provvigione1_Usr))

	Thisform.AddProperty('Exists_xDORig_Defaults_Provvigione2_Usr' , !IsNull(oRet.xDORig_Defaults_Provvigione2_Usr))



EndIf

ENDPROC

PROCEDURE setdorig_defaults_di

** cScope = DEF; FOR



Lparameters cScope



Local oData, cOldkey, lSkip, cDoIntento

Local cBufEdit, cBufExcl



** EXIT: Non è applicabile la dichiarazione

** EXIT: non è specificato alcune codice iva

** EXIT: esiste una dichiarazione sulla riga evasa

** EXIT: Non è dichiarato il CF

** EXIT: Non è indicato il cambio

** EXIT: Non si applica ai componenti espliciti (TIPOPC)

** EXIT: Non si applica ai doc non esecutivi se non è richiesta inclusione esplicita (DO.DIExecutive)



** Faccio pulizia di alcuni campi per normalizzare eventuali situazioni anomale



** Per i componenti non devo applicare nulla

If Nvl(DoRig.TipoPC, '') == 'C' And !IsEmpty(DoRig.Cd_Aliquota_e)

	Replace DoRig.Cd_Aliquota_e With Null In DoRig

Endif



** In assenza di codice iva elimino anche quello per dichiarazione intento

If IsEmpty(DoRig.Cd_Aliquota) And !IsEmpty(DoRig.Cd_Aliquota_e)

	Replace DoRig.Cd_Aliquota_e With Null In DoRig

Endif



** Ripulisco in caso venga eliminato il codice di esenzione (metto codice anche in DE)

If IsEmpty(DoRig.Cd_Aliquota_e) And !IsEmpty(DoRig.DoIntento)

	Replace DoRig.DoIntento With Null In DoRig

EndIf



** Condizioni di NON APPLICAZIONE

If !Thisform.DoIntento Or ;

	IsEmpty(DoRig.Cd_Aliquota) Or ;

	IsEmpty(Substr(NEvl(Dotes.Cd_CF_Fatt, Dotes.Cd_CF), 2)) Or ;

	IsEmpty(Dotes.Cambio) Or Nvl(Dorig.TipoPC, '') == 'C' Or ;

	!IsNull(Thisform.DoIntento_Evade('R', DoRig.Id_Dorig_Evade)) Or ;

	(DoTes.DISave And Bitand(Thisform.Mode, FEDIMODE_INS_DUP) != 0)



**	(!Dotes.Esecutivo And !Dotes.DIExecutive)

	

	Return .T.

EndIf



lSkip = (PemStatus(This.Grid.ColDoIntento.StdText1, 'SkipCheck', 5) And This.Grid.ColDoIntento.StdText1.SkipCheck)

AddProperty(This.Grid.ColDoIntento.StdText1, 'SkipCheck', .F.)



** EXIT: Forzo il mancato ricalcolo (OnValueChange Cd_Aliquota_e)

If lSkip

	Return .T.

EndIf



** Per dare priorità alle righe rispetto alle spese ripulisco l'applicazione di tutte le spese e poi la riapplico

Thisform.DOIntento_Clear(0x02)



cScope 		= Upper(xDefault(cScope, 'DEF'))

cDoIntento	= DoRig.DoIntento

cBufExcl 	= Iif(cScope == 'DEF', Null, Thisform.oDointento.Get_Buffer_Esclude('DORIG', 'DORIGSPESA', 0, .F., .T.))



** La riga corrente non deve essere considerata come buffer di utilizzo 

Replace DoIntento With Null In DoRig

cBufEdit = Iif(cScope == 'DEF', Null, Thisform.oDointento.Get_Buffer_Edit('DORIG', 'DORIGSPESA', 0, .F., .F.))

Replace DoIntento With cDoIntento In DoRig



oData = Thisform.oDointento.Get_Aliquota( ;

	  NEvl(Dotes.Cd_CF_Fatt, Dotes.Cd_CF) ;

	, Dotes.Cd_DO ;

	, Dorig.Cd_Ar ;

	, Dorig.Cd_Aliquota ;

	, Dorig.Cd_ReverseCharge ;

	, NEvl(Iif(Dotes.Clifor == 'F', Dotes.DataDocRif, Null), Dotes.DataDoc) ;

	, Iif(cScope == 'DEF', 1, Round(Dorig.PrezzoTotaleV/DoTes.Cambio, 2)) ;

	, Dotes.ImportiIvati ;

	, Dotes.Esecutivo ;

	, Dorig.Id_Dorig_Evade ;

	, Null ;

	, cBufExcl ;

	, cBufEdit)



If Vartype(oData) = 'O'



	If Thisform.oDoIntento.WrkEnabled

		cOldkey = Thisform.oDoIntento.Wrk_GetKey(DoRig.DoIntento)

		oData.ExtraInfo = Thisform.oDoIntento.Wrk_SetKey(oData.ExtraInfo, cOldkey)

	EndIf

			

	Replace ;

		Cd_Aliquota_e 	With oData.Cd_Aliquota_e ;

		Cd_Aliquota_r 	With oData.Cd_Aliquota_r ;

		DoIntento		With Iif(cScope == 'DEF', Null, oData.ExtraInfo) ;

		DoIntentoCode	With Iif(cScope == 'DEF', Null, oData.ErrorCode) ;

		In Dorig

	

	Iif(Thisform.oDoIntento.WrkEnabled, Thisform.oDoIntento.Wrk_Update(DoRig.DoIntento), .T.)

	

EndIf



Thisform.DOIntento_Apply(0x02)



ENDPROC

PROCEDURE setdorig_defaults_iva

Lparameters oRec



**	oRec = FKRECORD -> In mancanza rilevo il record da Dorig.Cd_Aliquota_r



** Viene richiamato in POSTFORMULAE una sola volta in modo accentrato

Replace Cd_Aliquota_r With Nevl(DoRig.Cd_Aliquota_e, DoRig.Cd_Aliquota) In Dorig



oRec = Iif(Vartype(oRec) != 'O', xSqlExec2Obj(Textmerge('Select * From Aliquota Where Cd_aliquota = <<FormatC4Spt(Dorig.Cd_Aliquota_r)>>'), .T.), oRec)



Replace ;

	IvaMoss			With oRec.Ivamoss ;

	IvaSplit			With oRec.IvaSplit ;

	Iva_Split_Sep	With (oRec.Iva_Split_Sep And DoTes.Clifor != 'C') ;

	Cd_RC				With oRec.Cd_ReverseCharge ;

In DoRig



Iif(!PemStatus(This, 'RC_OnValueChange', 5), AddProperty(This, 'RC_OnValueChange', .F.), .T.)

Iif(!PemStatus(This, 'IVA_OnValueChange', 5), AddProperty(This, 'IVA_OnValueChange', .F.), .T.)



Iif(This.RC_OnValueChange Or !This.IVA_OnValueChange, Thisform.SetRegimeIva('ONEROW+R-RC'), Thisform.SetRegimeIva('ONEROW+R'))



AddProperty(This, 'RC_OnValueChange', .F.)

AddProperty(This, 'IVA_OnValueChange', .F.)



ENDPROC

PROCEDURE Init

Lparameters oPage



DoDefault(oPage)

This.Grid.InitAutoSaveLayout()



** Questo codice è in relazione con quello nel metodo OnRefresh della form

** di dettaglio Detail e con quello nel Grid_When di questo stesso pgRighe

This.Grid.colQtaEvadibile.Enabled = (oApp.UserRightLevel >= RL_POWER_USER)



** ----- LICADAPTER

With This.Grid



	If !(oApp.LicInfo.DO_Ato Or oApp.LicInfo.DB_Varianti)

		.ColDistinta				  .ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

		.ColDistinta.btnDistinta  .ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

		.ColDistinta.btnNoDistinta.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

	Endif



	If !oApp.LicInfo.Commesse

		.ColCd_DOSottoCommessa.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

	Endif



	If !oApp.LicInfo.DO_LottiMatr

		.ColCd_ARLotto.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

	Endif



	If !oApp.LicInfo.MG_Main

		.ColCd_MG_P          .ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

		.ColCd_MG_A          .ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

		.ColCd_MGUbicazione_P.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

		.ColCd_MGUbicazione_A.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

	Endif



	If !oApp.LicInfo.CG_Main

		.ColRR_DataInizio.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

		.ColRR_DataFine  .ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

		.ColRR_Cd_CGConto.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

	Endif



	If !oApp.LicInfo.CA_Main

		.ColCd_CAVda    .ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

		.ColCd_CACda    .ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

		.ColCd_CAFormula.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

		.ColCAPartenza  .ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

		.ColCADurata    .ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

	Endif



Endwith



**************************************



If !InArtel() Or !Used('DoUiCfg') Or Eof('DoUiCfg')

	Return

Endif



If !DoUiCfg.RigheDettaglio

	This.Grid.ColDettagli.Visible = .F.

Endif

If !DoUiCfg.RigheDistinta

	This.Grid.ColDistinta.Visible = .F.

Endif

If !DoUiCfg.RigheLotto

	This.Grid.ColCd_ARLotto.Visible = .F.

Endif

If !DoUiCfg.RigheCommessa

	This.Grid.ColCd_DOSottoCommessa.Visible = .F.

Endif

If !DoUiCfg.RigheDataConsegna

	This.Grid.ColDataConsegna.Visible = .F.

Endif

If DoUiCfg.RigheMagazzino

	If !DoUiCfg.RigheUbicazione

		This.Grid.ColCd_MGUbicazione_P.Visible = .F.

		This.Grid.ColCd_MGUbicazione_A.Visible = .F.

	Endif

Else

	This.Grid.ColCd_MGUbicazione_P.Visible = .F.

	This.Grid.ColCd_MGUbicazione_A.Visible = .F.

	This.Grid.ColCd_MG_P          .Visible = .F.

	This.Grid.ColCd_MG_A          .Visible = .F.

Endif

If !DoUiCfg.RigheSconto

	This.Grid.ColScontoRiga.Visible = .F.

Endif

If !DoUiCfg.RigheProvvigione1

	This.Grid.ColProvvigioneRiga_1.Visible = .F.

Endif

If !DoUiCfg.RigheProvvigione2

	This.Grid.ColProvvigioneRiga_2.Visible = .F.

Endif

If !DoUiCfg.RigheUnitaMisura

	This.Grid.ColCd_ARMisura .Visible = .F.

	This.Grid.ColFattoreToUM1.Visible = .F.

Endif





ENDPROC


*======================================================================

*** CLASS / OBJECT: stdText1 (BaseClass: textbox, Parent: pgrighe.Grid.ColCd_AR) ***
*** PROPERTIES ***
BorderStyle = 0

Left = 247

Margin = 0

Top = 98

Name = "stdText1"


*** METHODS ***
PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif

Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE fkgetcodcf

Return ThisForm.PF.pgGenerale.txtCd_CF.Field.Value



ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC


*======================================================================

*** CLASS / OBJECT: stdText1 (BaseClass: textbox, Parent: pgrighe.Grid.ColQta) ***
*** PROPERTIES ***
Comment = "6C502209-9B0D-4622-8154-A4FDCBE3BC69"

FontSize = 8

BorderStyle = 0

Left = 19

Margin = 0

Top = 71

Name = "stdText1"


*** METHODS ***
PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC

PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif

Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC


*======================================================================

*** CLASS / OBJECT: stdText1 (BaseClass: textbox, Parent: pgrighe.Grid.ColCd_Aliquota) ***
*** PROPERTIES ***
FontSize = 8

BorderStyle = 0

Format = "!"

Margin = 0

Top = 11

Width = 25

fkselect = Select * From Aliquota Where Cd_Aliquota = <TEXT> And IvaSplit = 0

fkdecodedfield = Descrizione

Name = "stdText1"


*** METHODS ***
PROCEDURE fkselect_access

Return 	This.FKSelect + ;

			Iif(!Thisform.IvaMoss_Set(), ' And Aliquota.IvaMoss = 0', '')





ENDPROC

PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif

Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC


*======================================================================

*** CLASS / OBJECT: stdText1 (BaseClass: textbox, Parent: pgrighe.Grid.ColCd_MG_P) ***
*** PROPERTIES ***
FontSize = 8

BorderStyle = 0

Left = 32

Margin = 0

Top = 47

fktabledesc = Magazzini (Partenza)

Name = "stdText1"


*** METHODS ***
PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf



Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC

PROCEDURE fkgetcodar

Return DORig.Cd_AR



ENDPROC

PROCEDURE fkgetcodmges

Return DOTes.Cd_MGEsercizio



ENDPROC


*======================================================================

*** CLASS / OBJECT: stdText1 (BaseClass: textbox, Parent: pgrighe.Grid.ColCd_MG_A) ***
*** PROPERTIES ***
FontSize = 8

BorderStyle = 0

Left = 25

Margin = 0

Top = 59

fktabledesc = Magazzini (Arrivo)

Name = "stdText1"


*** METHODS ***
PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif

Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC

PROCEDURE fkgetcodar

Return DORig.Cd_AR



ENDPROC

PROCEDURE fkgetcodmges

Return DOTes.Cd_MGEsercizio



ENDPROC


*======================================================================

*** CLASS / OBJECT: stdText1 (BaseClass: textbox, Parent: pgrighe.Grid.ColCd_ARLotto) ***
*** PROPERTIES ***
FontSize = 8

BorderStyle = 0

Left = 39

Margin = 0

Top = 83

fktabledesc = Lotti

canchangemg = .T.

Name = "stdText1"


*** METHODS ***
PROCEDURE autoinsertinit

Lparameters oParam



DoDefault(oParam)



oParam.ARLotto.Cd_CF	= DOTes.Cd_CF

ENDPROC

PROCEDURE contextmenuproc

Lparameters nCBMId, xPar1, lFromCode



** Questo codice viene richiamato la prima volta dal menu (con lFromCode == .F.); la chiamata da menu

** deve essere rigirata nel metodo centralizzato Grid_ContextMenuProc,  che poi provvede a richiamare

** questo metodo, stavolta con lFromCode == .T. in modo da evitare la ricorsione



If !lFromCode

	Return This.Parent.Parent.Parent.Grid_ContextMenuProc(This, .F., nCBMId, xPar1)

Else

	Return DoDefault(nCBMId, xPar1)

EndIf

ENDPROC

PROCEDURE onvaluepick

LParameters nSearchFormType, xValue4Value, oSelectedRec, lFromCode



** Questo codice viene richiamato la prima volta dal menu (con lFromCode == .F.); la chiamata da menu

** deve essere rigirata nel metodo centralizzato Grid_OnValuePick, che poi provvede a richiamare

** questo metodo, stavolta con lFromCode == .T. in modo da evitare la ricorsione



If !lFromCode

	Return This.Parent.Parent.Parent.Grid_OnValuePick(This, .F., nSearchFormType, xValue4Value, oSelectedRec)

Else

	Return DoDefault(nSearchFormType, xValue4Value, oSelectedRec)

EndIf



ENDPROC

PROCEDURE fkgetcodmg

Return Iif(!IsEmpty(DORig.Cd_MG_P), DORig.Cd_MG_P, DORig.Cd_MG_A)

ENDPROC

PROCEDURE fkgetcodar

Return DoRig.Cd_AR

ENDPROC

PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif

Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC

PROCEDURE fkgetcodmges

Return DOTes.Cd_MGEsercizio



ENDPROC

PROCEDURE fkgetcodmgubicazione

Return Iif(!IsEmpty(DORig.Cd_MG_P), DORig.Cd_MGUbicazione_P, DORig.Cd_MGUbicazione_A)

ENDPROC

PROCEDURE fkgetautoinsertmode

Return Evaluate(ThisForm.PF.pgGenerale.txtCd_DO.Field.FKAlias + '.ARLottoAuto')

ENDPROC


*======================================================================

*** CLASS / OBJECT: stdText1 (BaseClass: textbox, Parent: pgrighe.Grid.ColCd_MGUbicazione_P) ***
*** PROPERTIES ***
FontSize = 8

BorderStyle = 0

Left = 56

Margin = 0

Top = 71

fktabledesc = Ubicazioni (Partenza)

canchangemg = .T.

Name = "stdText1"


*** METHODS ***
PROCEDURE fkgetcodmges

Return DOTes.Cd_MGEsercizio



ENDPROC

PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif

Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC

PROCEDURE fkgetcodar

Return DORig.Cd_AR



ENDPROC

PROCEDURE fkgetcodmg

Return DORig.Cd_MG_P



ENDPROC

PROCEDURE onvaluepick

LParameters nSearchFormType, xValue4Value, oSelectedRec, lFromCode



** Questo codice viene richiamato la prima volta dal menu (con lFromCode == .F.); la chiamata da menu

** deve essere rigirata nel metodo centralizzato Grid_OnValuePick, che poi provvede a richiamare

** questo metodo, stavolta con lFromCode == .T. in modo da evitare la ricorsione



If !lFromCode

	Return This.Parent.Parent.Parent.Grid_OnValuePick(This, .F., nSearchFormType, xValue4Value, oSelectedRec)

Else

	Return DoDefault(nSearchFormType, xValue4Value, oSelectedRec)

EndIf



ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC


*======================================================================

*** CLASS / OBJECT: stdText1 (BaseClass: textbox, Parent: pgrighe.Grid.ColCd_MGUbicazione_A) ***
*** PROPERTIES ***
FontSize = 8

BorderStyle = 0

Left = 40

Margin = 0

Top = 59

fktabledesc = Ubicazioni (Arrivo)

canchangemg = .T.

Name = "stdText1"


*** METHODS ***
PROCEDURE fkgetcodmges

Return DOTes.Cd_MGEsercizio



ENDPROC

PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif

Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC

PROCEDURE fkgetcodar

Return DORig.Cd_AR



ENDPROC

PROCEDURE fkgetcodmg

Return DORig.Cd_MG_A



ENDPROC

PROCEDURE onvaluepick

LParameters nSearchFormType, xValue4Value, oSelectedRec, lFromCode



** Questo codice viene richiamato la prima volta dal menu (con lFromCode == .F.); la chiamata da menu

** deve essere rigirata nel metodo centralizzato Grid_OnValuePick, che poi provvede a richiamare

** questo metodo, stavolta con lFromCode == .T. in modo da evitare la ricorsione



If !lFromCode

	Return This.Parent.Parent.Parent.Grid_OnValuePick(This, .F., nSearchFormType, xValue4Value, oSelectedRec)

Else

	Return DoDefault(nSearchFormType, xValue4Value, oSelectedRec)

EndIf



ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC


*======================================================================

*** CLASS / OBJECT: stdText1 (BaseClass: textbox, Parent: pgrighe.Grid.ColCd_DOSottoCommessa) ***
*** PROPERTIES ***
FontSize = 8

BorderStyle = 0

Format = "!"

Left = 49

Margin = 0

Top = 95

fkselect = SELECT * FROM DOSottoCommessa WHERE Cd_DOSottoCommessa = <TEXT>

fktabledesc = Sottocommessa

Name = "stdText1"


*** METHODS ***
PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif

Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE When

** Se il campo Sottocommessa della testa è valorizzato, non posso modificare la sottocommessa nelle righe e quindi

** imposto il campo ReadOnly.

**

** Attenzione!! Non si può far ritornare .F. da questo metodo altrimenti non viene valorizzata la property .ValueOnGotFocus 

** e se si esegue cmdAnnulla con il fuoco su questo campo (n.b. il fuoco viene dato anche se si ritorna .F. sul WHEN perche il controllo è su una colonna)

** viene sostituita la property .Value con .ValueOnGotFocus, cioè .F.



This.Parent.ReadOnly = !IsEmpty(DoTes.Cd_DOSottoCommessa) Or Thisform.Mode = FEDIMODE_SHOW

Return DoDefault()



** Utilizzando Col_SetCross In Grid.Init()

** Return (DoDefault() And (IsEmpty(DoTes.Cd_DOSottoCommessa) Or Thisform.Mode = FEDIMODE_SHOW))



ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC


*======================================================================

*** CLASS / OBJECT: stdText1 (BaseClass: textbox, Parent: pgrighe.Grid.ColId_MGMov_Carico) ***
*** PROPERTIES ***
Left = 638

Top = 283

Name = "stdText1"


*** METHODS ***
PROCEDURE onvaluechange

LParameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif

Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC

PROCEDURE contextmenuproc

Lparameters nCBMId, xPar1, lFromCode



** Questo codice viene richiamato la prima volta dal menu (con lFromCode == .F.); la chiamata da menu

** deve essere rigirata nel metodo centralizzato Grid_ContextMenuProc,  che poi provvede a richiamare

** questo metodo, stavolta con lFromCode == .T. in modo da evitare la ricorsione



If !lFromCode

	Return This.Parent.Parent.Parent.Grid_ContextMenuProc(This, .F., nCBMId, xPar1)

Else

	&& Return txtbase::ContextMenuProc(nCBMId, xPar1) 

	Return DoDefault(nCBMId, xPar1)

	* Return DoDefault(nCBMId, xPar1, MB_EDIT_SRCDTL_DISABLED + MB_EDIT_SRCFEDI_DISABLED + MB_EDIT_SRCFULL_DISABLED)

Endif



**	MB_EDIT_SRCDTL_DISABLED

**	MB_EDIT_SRCFULL_DISABLED

**	MB_EDIT_SRCFEDI_DISABLED

**	MB_EDIT_SRCFAST_DISABLED



ENDPROC

PROCEDURE KeyPress

LParameters nKeyCode, nShiftAltCtrl



If nKeyCode = -2 																&& F3 - Fast Search

	This.ContextMenuProc(CMM_PROCESS_CHOICE, MB_EDIT_SRCHSPEC0)	

	NoDefault

	Return .T.

EndIf



If (nKeyCode = 67 Or nKeyCode = 99) And nShiftAltCtrl = 0 		&& c - Cancella riferimento riga

	This.ContextMenuProc(CMM_PROCESS_CHOICE, MB_EDIT_SRCHSPEC1)

	NoDefault

	Return .T.

EndIf



Return DoDefault(nKeyCode, nShiftAltCtrl)



ENDPROC


*======================================================================

*** CLASS / OBJECT: spcConto1 (BaseClass: textbox, Parent: pgrighe.Grid.ColCd_CGConto) ***
*** PROPERTIES ***
BorderStyle = 0

Left = 25

Margin = 0

Top = 75

Name = "spcConto1"


*** METHODS ***
PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC

PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif

Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC


*======================================================================

*** CLASS / OBJECT: btnDettaglio (BaseClass: commandbutton, Parent: pgrighe.Grid.ColDettagli) ***
*** PROPERTIES ***
Comment = "FAC04D20-B638-49BD-86DD-F03EA0F6E628"

Top = 99

Left = 19

Caption = "..."

TabStop = .F.

ToolTipText = "Dettaglio riga"

Name = "btnDettaglio"


*** METHODS ***
PROCEDURE Click

WITH THIS.Parent.Parent.Parent

	IF THISFORM.DE.DORig.ReccountND() > 0

		THIS.SetFocus()            && Necessario nel caso di chiamate da menu.

		IF ThisForm.Mode = FEDIMODE_SHOW AND TAGNO('Id_DoRig') = 0

			THISFORM.DE.DoRigPackList.RunCmd('SET FILTER TO Id_DORig = xDefault(DORig.Id_DoRig, RECNO("DORig"))')

		ENDIF



		.RowDetailForm = RunDetail(JUSTSTEM(THISFORM.ClassLibrary), THISFORM, This.Parent.Parent)

		.RowDetailForm.Caption = 'Dettaglio righe documento'		

		IF ThisForm.Mode = FEDIMODE_SHOW

			.RowDetailForm.SetAll('Readonly', .T.)

		EndIf

		.RowDetailForm.SHOW(1)

		.RowDetailForm = NULL

	ENDIF

ENDWITH



ENDPROC


*======================================================================

*** CLASS / OBJECT: btnDistinta (BaseClass: commandbutton, Parent: pgrighe.Grid.ColDistinta) ***
*** PROPERTIES ***
Comment = "706D4D06-350A-40E2-B42A-0B8CF9D69292"

Top = 71

Left = 7

FontSize = 8

Caption = ""

TabStop = .F.

ToolTipText = "Distinta base particolare"

Visible = .T.

Name = "btnDistinta"


*** METHODS ***
PROCEDURE Init

If !DoDefault()

	Return .F.

Endif

This.AddProperty('ControlSource', 'DoRig.Id_DoDB')

SetPictureProp(This, 'images\included\Tree1.Bmp')



ENDPROC

PROCEDURE Click

Return This.Parent.Parent.Parent.Grid_Click(This, .F.)



ENDPROC


*======================================================================

*** CLASS / OBJECT: btnNoDistinta (BaseClass: commandbutton, Parent: pgrighe.Grid.ColDistinta) ***
*** PROPERTIES ***
Comment = "97E40D80-6565-498E-8056-5851E206964D"

Top = 95

Left = 11

Caption = ""

Enabled = .F.

TabStop = .F.

ToolTipText = "Distinta base particolare"

Name = "btnNoDistinta"


*** METHODS ***
PROCEDURE Init

If !DoDefault()

	Return .F.

Endif

This.AddProperty('ControlSource', 'DoRig.Id_DoDB')



ENDPROC

PROCEDURE Click

Return This.Parent.Parent.Parent.Grid_Click(This, .F.)



ENDPROC


*======================================================================

*** CLASS / OBJECT: spcCaVda1 (BaseClass: textbox, Parent: pgrighe.Grid.ColCd_CAVda) ***
*** PROPERTIES ***
BorderStyle = 0

Left = 47

Margin = 0

Top = 57

Name = "spcCaVda1"


*** METHODS ***
PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif

Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC


*======================================================================

*** CLASS / OBJECT: spcCaCda1 (BaseClass: textbox, Parent: pgrighe.Grid.ColCd_CACda) ***
*** PROPERTIES ***
BorderStyle = 0

Left = 65

Margin = 0

Top = 121

Name = "spcCaCda1"


*** METHODS ***
PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif

Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC


*======================================================================

*** CLASS / OBJECT: cmb_CaOfs (BaseClass: combobox, Parent: pgrighe.Grid.ColCAPartenza) ***
*** PROPERTIES ***
Comment = "D1DC5009-CB99-4B8E-A6A4-AC80CAC55E4D"

Left = 35

SpecialEffect = 1

Top = 69

Name = "cmb_CaOfs"


*** METHODS ***
PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)



ENDPROC

PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

EndIf



Return This.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue, lIsChanged)



ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



Return This.Parent.Parent.Parent.Grid_OnValueChange(This, .F., xOldValue)





ENDPROC


*======================================================================

*** CLASS / OBJECT: Text (BaseClass: textbox, Parent: pgrighe.Grid.colNote) ***
*** PROPERTIES ***
Comment = "51C81F9F-B9EA-4D6E-8CF8-B94178525863"

BorderStyle = 0

Left = 16

Margin = 0

Top = 41

Name = "Text"


*** METHODS ***
PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)

ENDPROC

PROCEDURE contextmenuproc

Lparameters nCBMId, xPar1



**	nCBMId == CMM_ADD_ITEMS_TO_CONTEXT_MENU	-> xPar1 oggetto oMenu di classe ShortcutMenu 	

**	nCBMId == CMM_ADD_ITEMS_TO_EDIT_PAD			-> xPar1 Edit Popup Name								

**	nCBMId == CMM_PROCESS_CHOICE					-> xPar1 choice id (numerico)							- RetVal .T. se choice id riconosciuta e processata, .f. in caso contrario



Local cXml, cNotaXML

Local oXml, oGNodes, oGNode



Do Case



	Case nCBMId == CMM_ADD_ITEMS_TO_CONTEXT_MENU			&& xPar1 oggetto oMenu di classe ShortcutMenu 



		Local oMenu, oMenu1

		Local lBrwSpc0, lDisabled

		

		DoDefault(nCBMId, xPar1)		

		

		If This.Enabled And !This.ReadOnly And !IsEmpty(DoRig.Cd_AR) 

			oMenu = xPar1



			This.Parent.Parent.ColCd_AR.StdText1.Refresh()



			lBrwSpc0 =  (PemStatus(This, 'BrwSpc0', 5) = .F. Or This.BrwSpc0) And !IsEmpty(This.Parent.Parent.ColCd_AR.StdText1.FKRecord.Note_AR)

			oMenu.AddMenuBar('\-'						 ,	,      						, MB_EDIT_SEP_SEARCH)		



			xSqlExec("Select Id_Nota, Descrizione From Nota Where UsedBy = 'AR' Order by Descrizione", "crNote") 

			

			If Reccount('crNote') = 0

				** Ci sono solo le note principali

				oMenu.AddMenuBar(Thisform.TM_(,"C4FBC030-419F-45B7-A4E6-FB129EA411DC", "Replica note articolo %1!", Rtrim(This.Parent.Parent.ColCd_AR.StdText1.FKRecord.Cd_AR)), , 'Key CTRL+N, "Ctrl+N"', MB_EDIT_SRCHSPEC0,,!lBrwSpc0,, "Images\MnuImages\Copy.bmp")



			Else

				** Esistono NoteXML				



				oMenu1 = oMenu.NewMenu()

				oMenu1.AddMenuBar(Thisform.TM_(,"74E9F56F-2CB8-46FF-9C92-95055AB8A3B9", "Note Principali"), , 'Key CTRL+N, "Ctrl+N"', MB_EDIT_SRCHSPEC0,,!lBrwSpc0)

				

				cXml = Nvl(xSqlExec2Var('Select Convert(Varchar(max), NoteXML) From AR Where Cd_AR = ' + FormatC4Spt(This.Parent.Parent.ColCd_AR.StdText1.FKRecord.NoteXML)), '')

				oXml = NewDomDocument(cXml)

				oGNodes = oXml.selectNodes('rows/row')



				Select crNote

				Scan

					lDisabled = .T.

					For Each oGNode In oGNodes	

						If Val(Nvl(oGNode.GetAttribute('nota'), 0)) = crNote.Id_Nota

							lDisabled = .F.

							Exit

						EndIf 

					Next 				

					oMenu1.AddMenuBar(crNote.Descrizione, , , 1000 + crNote.Id_Nota,, lDisabled)					

				EndScan

	

				oMenu.AddMenuBar(Thisform.TM_(,"74E9F56F-2CB8-46FF-9C92-95055AB8A3B9", "Replica note articolo %1!", Rtrim(This.Parent.Parent.ColCd_AR.StdText1.FKRecord.Cd_AR)), oMenu1,,,,,, "Images\MnuImages\Copy.bmp")

			

			EndIf 

			

			Use In crNote

			

		EndIf

		

		Return .T.



	Case nCBMId == CMM_ADD_ITEMS_TO_EDIT_PAD		&& xPar1 Edit Popup Name 

		

		Local cPopupName, cOnSelCmd, cBrwSpc0, cSkipFor, cForm

		

		DoDefault(nCBMId, xPar1) 	

		

		If This.Enabled And !This.ReadOnly And !IsEmpty(DoRig.Cd_AR)

			cPopupName = xPar1

			cForm		  = Thisform.Name



			This.Parent.Parent.ColCd_AR.StdText1.Refresh()



			cBrwSpc0 = Transform((PemStatus(This, 'BrwSpc0', 5) = .F. Or This.BrwSpc0) And !IsEmpty(This.Parent.Parent.ColCd_AR.StdText1.FKRecord.Note_AR))



			xSqlExec("Select Id_Nota, Descrizione From Nota Where UsedBy = 'AR' Order by Descrizione", "crNote") 

			

			If Reccount('crNote') = 0

				** Ci sono solo le note principali



				DefineBar(999					, cPopupName, [Prompt "\-"])

				DefineBar(MB_EDIT_SRCHSPEC0, cPopupName, [Key Ctrl+N, "Ctrl+N" Prompt &cForm..TM_(,"20E42A7B-1BF1-4B94-830E-D76301A10F73", "Replica note articolo") Picture "Images\MnuImages\Copy.bmp"  Skip For !&cBrwSpc0])



				cOnSelCmd =  Sys(1272, This) + '.ContextMenuProc(' + Transform(CMM_PROCESS_CHOICE) + ', ' + Transform(MB_EDIT_SRCHSPEC0) + ')'

				On Selection 	Bar (MB_EDIT_SRCHSPEC0) Of (cPopupName) &cOnSelCmd

			

			Else

				** Esistono NoteXML	



				DefineBar(98, cPopupName, [Prompt "\-"])

				DefineBar(99, cPopupName, [Prompt &cForm..TM_(,"FCEBDCFB-B471-4A65-BDE4-9BF2BE10AE6D", "Replica note articolo") Picture "Images\MnuImages\Copy.bmp"])



				cSubPopupName = cPopupName + '_99'

				On Bar 99 Of (cPopupName) Activate Popup (cSubPopupName)

				Define Popup (cSubPopupName) Margin Relative Shadow Color Scheme 4



				DefineBar(MB_EDIT_SRCHSPEC0, cSubPopupName, [Key Ctrl+N, "Ctrl+N" Prompt &cForm..TM_(,"341B5967-EA4E-40B4-913F-64BB4549D1CB", "Note Principali") Skip For !&cBrwSpc0])			

				cOnSelCmd =  Sys(1272, This) + '.ContextMenuProc(' + Transform(CMM_PROCESS_CHOICE) + ', ' + Transform(MB_EDIT_SRCHSPEC0) + ')'

				On Selection 	Bar (MB_EDIT_SRCHSPEC0) Of (cSubPopupName) &cOnSelCmd



				cXml = Nvl(xSqlExec2Var('Select Convert(Varchar(max), NoteXML) From AR Where Cd_AR = ' + FormatC4Spt(This.Parent.Parent.ColCd_AR.StdText1.FKRecord.NoteXML)), '')				

				oXml = NewDomDocument(cXml)

				oGNodes = oXml.selectNodes('rows/row')

								

				Select crNote

				Scan



					cSkipFor = '1=1'

					For Each oGNode In oGNodes	

						If Val(Nvl(oGNode.GetAttribute('nota'), 0)) = crNote.Id_Nota

							cSkipFor = '1=0'

							Exit

						EndIf 

					Next 				



					DefineBar(1000 + crNote.Id_Nota, cSubPopupName, 'Prompt "' + Rtrim(crNote.Descrizione) + '" Skip For ' + cSkipFor)

					cOnSelCmd =  Sys(1272, This) + '.ContextMenuProc(' + Transform(CMM_PROCESS_CHOICE) + ', ' + Transform(1000 + crNote.Id_Nota) + ')'

					On Selection 	Bar (1000 + crNote.Id_Nota) Of (cSubPopupName) &cOnSelCmd

				

				EndScan			



				Use In crNote

			EndIf 



		EndIf

		

		Return .T.

		

	Case nCBMId == CMM_PROCESS_CHOICE						&& xPar1 nChoiceId - Torna .T. nel caso nChoiceId sia stato processato



		Local nChoiceId



		nChoiceId  = xPar1



		Do Case

			Case nChoiceId == MB_EDIT_SRCHSPEC0

				If This.Enabled And !This.ReadOnly And !IsEmpty(DoRig.Cd_AR) And !IsEmpty(This.Parent.Parent.ColCd_AR.StdText1.FKRecord.Note_AR)

					If !IsEmpty(This.Value) And xMessageBox(Thisform.TB_(,"01B6B437-315F-4170-B8C6-4962F4D2EFC9", 'Accodare le note articolo alle note già presenti ?'), MB_YESNO + MB_ICONQUESTION) == IDYES

						This.Value = Nvl(This.Value, '') + CRLF + This.Parent.Parent.ColCd_AR.StdText1.FKRecord.Note_AR

					Else

						This.Value = This.Parent.Parent.ColCd_AR.StdText1.FKRecord.Note_AR

					EndIf

					This.Refresh()

				EndIf 

				Return .T.

			

			Case nChoiceId > 1000

				** Replica di NoteXML

				

				cXml = Nvl(xSqlExec2Var('Select Convert(Varchar(max), NoteXML) From AR Where Cd_AR = ' + FormatC4Spt(This.Parent.Parent.ColCd_AR.StdText1.FKRecord.NoteXML)), '')				

				oXml = NewDomDocument(cXml)

				oGNodes = oXml.selectNodes('rows/row')

				For Each oGNode In oGNodes	

					If Val(Nvl(oGNode.GetAttribute('nota'), 0)) = (nChoiceId - 1000)

						cNotaXml = oGNode.Text

						Exit

					EndIf 

				Next 

				

				If This.Enabled And !This.ReadOnly And !IsEmpty(DoRig.Cd_AR) And !IsEmpty(cNotaXML)

					If !IsEmpty(This.Value) And xMessageBox(Thisform.TB_(,"01B6B437-315F-4170-B8C6-4962F4D2EFC9", 'Accodare le note articolo alle note già presenti ?'), MB_YESNO + MB_ICONQUESTION) == IDYES

						This.Value = Nvl(This.Value, '') + CRLF + cNotaXML

					Else

						This.Value = cNotaXML

					EndIf

					This.Refresh()		

				EndIf 

				Return .T.

			

			Otherwise

				Return DoDefault(nCBMId, nChoiceId)

		EndCase

			

EndCase

ENDPROC

PROCEDURE KeyPress

LParameters nKeyCode, nShiftAltCtrl



If nKeyCode = 14 And nShiftAltCtrl = 2 								&& CTRL + N : Riporta note articolo

	This.ContextMenuProc(CMM_PROCESS_CHOICE, MB_EDIT_SRCHSPEC0)

	NoDefault

	Return .T.

Else

	Return DoDefault(nKeyCode, nShiftAltCtrl)

EndIf



ENDPROC


*======================================================================

*** CLASS / OBJECT: StdEdit (BaseClass: editbox, Parent: pgrighe.Grid.colNote) ***
*** PROPERTIES ***
BackStyle = 0

BorderStyle = 0

Left = 14

Margin = 0

SpecialEffect = 1

Top = 65

Name = "StdEdit"


*** METHODS ***
PROCEDURE contextmenuproc

Lparameters nCBMId, xPar1



**	nCBMId == CMM_ADD_ITEMS_TO_CONTEXT_MENU	-> xPar1 oggetto oMenu di classe ShortcutMenu 	

**	nCBMId == CMM_ADD_ITEMS_TO_EDIT_PAD			-> xPar1 Edit Popup Name								

**	nCBMId == CMM_PROCESS_CHOICE					-> xPar1 choice id (numerico)							- RetVal .T. se choice id riconosciuta e processata, .f. in caso contrario



Local cXml, cNotaXML

Local oXml, oGNodes, oGNode



Do Case



	Case nCBMId == CMM_ADD_ITEMS_TO_CONTEXT_MENU			&& xPar1 oggetto oMenu di classe ShortcutMenu 



		Local oMenu, oMenu1

		Local lBrwSpc0, lDisabled

		

		DoDefault(nCBMId, xPar1)		

		

		If This.Enabled And !This.ReadOnly And !IsEmpty(DoRig.Cd_AR) 

			oMenu = xPar1

			

			This.Parent.Parent.ColCd_AR.StdText1.Refresh()



			lBrwSpc0 =  (PemStatus(This, 'BrwSpc0', 5) = .F. Or This.BrwSpc0) And !IsEmpty(This.Parent.Parent.ColCd_AR.StdText1.FKRecord.Note_AR)

			oMenu.AddMenuBar('\-'						 ,	,      						, MB_EDIT_SEP_SEARCH)		



			xSqlExec("Select Id_Nota, Descrizione From Nota Where UsedBy = 'AR' Order by Descrizione", "crNote") 

			

			If Reccount('crNote') = 0

				** Ci sono solo le note principali

				oMenu.AddMenuBar(Thisform.TM_(,"C4FBC030-419F-45B7-A4E6-FB129EA411DC", "Replica note articolo %1!", Rtrim(This.Parent.Parent.ColCd_AR.StdText1.FKRecord.Cd_AR)), , 'Key CTRL+N, "Ctrl+N"', MB_EDIT_SRCHSPEC0,,!lBrwSpc0,, "Images\MnuImages\Copy.bmp")



			Else

				** Esistono NoteXML				



				oMenu1 = oMenu.NewMenu()

				oMenu1.AddMenuBar(Thisform.TM_(,"74E9F56F-2CB8-46FF-9C92-95055AB8A3B9", "Note Principali"), , 'Key CTRL+N, "Ctrl+N"', MB_EDIT_SRCHSPEC0,,!lBrwSpc0)

				

				cXml = Nvl(xSqlExec2Var('Select Convert(Varchar(Max), NoteXML) From AR Where Cd_AR = ' + FormatC4Spt(This.Parent.Parent.ColCd_AR.StdText1.Value)), '')

				oXml = NewDomDocument(cXml)

				oGNodes = oXml.selectNodes('rows/row')



				Select crNote

				Scan

					lDisabled = .T.

					For Each oGNode In oGNodes	

						If Val(Nvl(oGNode.GetAttribute('nota'), 0)) = crNote.Id_Nota

							lDisabled = .F.

							Exit

						EndIf 

					Next 				

					oMenu1.AddMenuBar(crNote.Descrizione, , , 1000 + crNote.Id_Nota,, lDisabled)					

				EndScan

	

				oMenu.AddMenuBar(Thisform.TM_(,"74E9F56F-2CB8-46FF-9C92-95055AB8A3B9", "Replica note articolo %1!", Rtrim(This.Parent.Parent.ColCd_AR.StdText1.FKRecord.Cd_AR)), oMenu1,,,,,, "Images\MnuImages\Copy.bmp")

			

			EndIf 

			

			Use In crNote

			

		EndIf

		

		Return .T.



	Case nCBMId == CMM_ADD_ITEMS_TO_EDIT_PAD		&& xPar1 Edit Popup Name 

		

		Local cPopupName, cOnSelCmd, cBrwSpc0, cSkipFor, cForm

		

		DoDefault(nCBMId, xPar1) 	

		

		If This.Enabled And !This.ReadOnly And !IsEmpty(DoRig.Cd_AR)

			cPopupName = xPar1

			cForm		  = Thisform.Name



			This.Parent.Parent.ColCd_AR.StdText1.Refresh()



			cBrwSpc0 = Transform((PemStatus(This, 'BrwSpc0', 5) = .F. Or This.BrwSpc0) And !IsEmpty(This.Parent.Parent.ColCd_AR.StdText1.FKRecord.Note_AR))



			xSqlExec("Select Id_Nota, Descrizione From Nota Where UsedBy = 'AR' Order by Descrizione", "crNote") 

			

			If Reccount('crNote') = 0

				** Ci sono solo le note principali



				DefineBar(999					, cPopupName, [Prompt "\-"])

				DefineBar(MB_EDIT_SRCHSPEC0, cPopupName, [Key Ctrl+N, "Ctrl+N" Prompt &cForm..TM_(,"20E42A7B-1BF1-4B94-830E-D76301A10F73", "Replica note articolo") Picture "Images\MnuImages\Copy.bmp"  Skip For !&cBrwSpc0])



				cOnSelCmd =  Sys(1272, This) + '.ContextMenuProc(' + Transform(CMM_PROCESS_CHOICE) + ', ' + Transform(MB_EDIT_SRCHSPEC0) + ')'

				On Selection 	Bar (MB_EDIT_SRCHSPEC0) Of (cPopupName) &cOnSelCmd

			

			Else

				** Esistono NoteXML	



				DefineBar(98, cPopupName, [Prompt "\-"])

				DefineBar(99, cPopupName, [Prompt &cForm..TM_(,"FCEBDCFB-B471-4A65-BDE4-9BF2BE10AE6D", "Replica note articolo") Picture "Images\MnuImages\Copy.bmp"])



				cSubPopupName = cPopupName + '_99'

				On Bar 99 Of (cPopupName) Activate Popup (cSubPopupName)

				Define Popup (cSubPopupName) Margin Relative Shadow Color Scheme 4



				DefineBar(MB_EDIT_SRCHSPEC0, cSubPopupName, [Key Ctrl+N, "Ctrl+N" Prompt &cForm..TM_(,"341B5967-EA4E-40B4-913F-64BB4549D1CB", "Note Principali") Skip For !&cBrwSpc0])			

				cOnSelCmd =  Sys(1272, This) + '.ContextMenuProc(' + Transform(CMM_PROCESS_CHOICE) + ', ' + Transform(MB_EDIT_SRCHSPEC0) + ')'

				On Selection 	Bar (MB_EDIT_SRCHSPEC0) Of (cSubPopupName) &cOnSelCmd



				cXml = Nvl(xSqlExec2Var('Select Convert(Varchar(Max), NoteXML) From AR Where Cd_AR = ' + FormatC4Spt(This.Parent.Parent.ColCd_AR.StdText1.Value)), '')

				oXml = NewDomDocument(cXml)

				oGNodes = oXml.selectNodes('rows/row')

								

				Select crNote

				Scan



					cSkipFor = '1=1'

					For Each oGNode In oGNodes	

						If Val(Nvl(oGNode.GetAttribute('nota'), 0)) = crNote.Id_Nota

							cSkipFor = '1=0'

							Exit

						EndIf 

					Next 				



					DefineBar(1000 + crNote.Id_Nota, cSubPopupName, 'Prompt "' + Rtrim(crNote.Descrizione) + '" Skip For ' + cSkipFor)

					cOnSelCmd =  Sys(1272, This) + '.ContextMenuProc(' + Transform(CMM_PROCESS_CHOICE) + ', ' + Transform(1000 + crNote.Id_Nota) + ')'

					On Selection 	Bar (1000 + crNote.Id_Nota) Of (cSubPopupName) &cOnSelCmd

				

				EndScan			



				Use In crNote

			EndIf 



		EndIf

		

		Return .T.

		

	Case nCBMId == CMM_PROCESS_CHOICE						&& xPar1 nChoiceId - Torna .T. nel caso nChoiceId sia stato processato



		Local nChoiceId



		nChoiceId  = xPar1



		Do Case

			Case nChoiceId == MB_EDIT_SRCHSPEC0

				If This.Enabled And !This.ReadOnly And !IsEmpty(DoRig.Cd_AR) And !IsEmpty(This.Parent.Parent.ColCd_AR.StdText1.FKRecord.Note_AR)

					If !IsEmpty(This.Value) And xMessageBox(Thisform.TB_(,"01B6B437-315F-4170-B8C6-4962F4D2EFC9", 'Accodare le note articolo alle note già presenti ?'), MB_YESNO + MB_ICONQUESTION) == IDYES

						This.Value = Nvl(This.Value, '') + CRLF + This.Parent.Parent.ColCd_AR.StdText1.FKRecord.Note_AR

					Else

						This.Value = This.Parent.Parent.ColCd_AR.StdText1.FKRecord.Note_AR

					EndIf

					This.Refresh()

				EndIf 

				Return .T.

			

			Case nChoiceId > 1000

				** Replica di NoteXML

				

				cXml = Nvl(xSqlExec2Var('Select Convert(Varchar(Max), NoteXML) From AR Where Cd_AR = ' + FormatC4Spt(This.Parent.Parent.ColCd_AR.StdText1.Value)), '')

				oXml = NewDomDocument(cXml)

				oGNodes = oXml.selectNodes('rows/row')

				For Each oGNode In oGNodes	

					If Val(Nvl(oGNode.GetAttribute('nota'), 0)) = (nChoiceId - 1000)

						cNotaXml = oGNode.Text

						Exit

					EndIf 

				Next 

				

				If This.Enabled And !This.ReadOnly And !IsEmpty(DoRig.Cd_AR) And !IsEmpty(cNotaXML)

					If !IsEmpty(This.Value) And xMessageBox(Thisform.TB_(,"01B6B437-315F-4170-B8C6-4962F4D2EFC9", 'Accodare le note articolo alle note già presenti ?'), MB_YESNO + MB_ICONQUESTION) == IDYES

						This.Value = Nvl(This.Value, '') + CRLF + cNotaXML

					Else

						This.Value = cNotaXML

					EndIf

					This.Refresh()		

				EndIf 

				Return .T.

			

			Otherwise

				Return DoDefault(nCBMId, nChoiceId)

		EndCase

			

EndCase

ENDPROC

PROCEDURE KeyPress

LParameters nKeyCode, nShiftAltCtrl



If nKeyCode = 14 And nShiftAltCtrl = 2 								&& CTRL + N : Riporta note articolo

	This.ContextMenuProc(CMM_PROCESS_CHOICE, MB_EDIT_SRCHSPEC0)

	NoDefault

	Return .T.

Else

	Return DoDefault(nKeyCode, nShiftAltCtrl)

EndIf



ENDPROC

PROCEDURE When

Return DoDefault() And This.Parent.Parent.Parent.Grid_When(This, .F.)

ENDPROC


*======================================================================

*** CLASS / OBJECT: lblLegend03 (BaseClass: label, Parent: pgrighe) ***
*** PROPERTIES ***
Comment = "F8977095-622C-4284-BF70-D2C2F3C54417"

Anchor = 4

BackStyle = 1

BorderStyle = 1

Caption = ""

Height = 12

Left = 3

Top = 279

Visible = .T.

Width = 12

TabIndex = 17

ZOrderSet = 7

Name = "lblLegend03"


*** METHODS ***
PROCEDURE Init

This.BackColor = oApp.ColorDecodedField

DoDefault()



ENDPROC


*======================================================================

*** CLASS / OBJECT: pgpiede (BaseClass: container, Parent: ) ***
*** PROPERTIES ***
Width = 580

Height = 284

BorderWidth = 0

Name = "pgpiede"


*** METHODS ***
PROCEDURE importovchange

LParameters nOldValue, nNewValue



Local nDeltaImportoV, nImportoEvadibileV, nImportoEvasoV



nNewValue = xDefault(nNewValue, DoRigSpesa.ImportoV)

nDeltaImportoV 	 = nNewValue - Nvl(nOldValue, 0)

nImportoEvadibileV = DoRigSpesa.ImportoEvadibileV + nDeltaImportoV

nImportoEvasoV     = DoRigSpesa.ImportoEvasoV



If !IsEmpty(DoRigSpesa.Id_DoRigSpesa_Evade)	&&--> la riga spesa evade un'altra riga spesa

*|	https://dev.azure.com/wkgenya/Arca/_workitems/edit/383385

*|	Considero sempre l'importo spesa indicato

*|		nImportoEvasoV = DoRigSpesa.ImportoEvasoV + nDeltaImportoV

	nImportoEvasoV = nNewValue

	If nImportoEvasoV > (DoRigSpesa.DocEvaso_ImportoEvadibileV + DORigSpesa.ImportoEvasoV_InOrigine)

		nImportoEvasoV = (DoRigSpesa.DocEvaso_ImportoEvadibileV + DORigSpesa.ImportoEvasoV_InOrigine)

	EndIf



EndIf



Replace ImportoEvasoV With nImportoEvasoV, ImportoEvadibileV With nImportoEvadibileV In DoRigSpesa



ENDPROC

PROCEDURE tipospesadisplay

LParameters cTipoDocumento, lInsertMode



Local cPrefix



cPrefix = Iif(InList(cTipoDocumento, 'F', 'A', 'N'), '', '\')



With This.CntFattura.Grid.ColTipoRigaSpesa.CmbTipoSpesa1

	For i = 1 To .ListCount

		If InList(.List(i, 2), 'N', 'B')

			.List(i, 1) = cPrefix + ChrTran(.List(i, 1), '\', '')

			.List(i, 2) = cPrefix + ChrTran(.List(i, 2), '\', '')

		Else

			If .List(i, 2) = 'Z' 

				If lInsertMode		&& in inserimento spese bolli su esente disabilitate sempre

					.List(i, 1) = '\' + ChrTran(.List(i, 1), '\', '')

					.List(i, 2) = '\' + ChrTran(.List(i, 2), '\', '')

				Else					&& in modifica abilitate solo sui documenti iva

					.List(i, 1) = cPrefix + ChrTran(.List(i, 1), '\', '')

					.List(i, 2) = cPrefix + ChrTran(.List(i, 2), '\', '')

				EndIf

			EndIf

		EndIf

	Next

EndWith



ENDPROC

PROCEDURE grid_isvalid

LParameters oControl, lFromDetailForm, xOldValue



Local cControlSource



cControlSource = AllTrim(Lower(oControl.ControlSource))



If Empty(cControlSource)		&& Quando vengono invocati i metodi .SaveRecordSource e RestoreRecordSource della griglia, si scatenano

	Return 							&& le valid e si riesce ad arrivare in punti come questo con il controlsource vuoto.

EndIf



If At('.', cControlSource) > 0 && Ricavo solo Nome delField

	cControlSource = JustExt(cControlSource)

EndIf



Do Case

Case cControlSource = 'importoevadibilev'

	If !IsEmpty(oControl.Value)

		Do Case

		Case Sign(oControl.Value) != Sign(DORigSpesa.ImportoV)

			xMessageBox(Thisform.TB_(,'E4097C8C-2C9F-4DB0-B06B-572343031B6B', "L'importo evadibile e l'importo della spesa devono avere lo stesso segno."), 16)

			Return .F.

		Case Abs(oControl.Value) > Abs(DORigSpesa.ImportoV)

			xMessageBox(Thisform.TB_(,'BB379734-0860-4492-ADC9-8A9A2C9B8E4A', "L'importo evadibile non può essere superiore all'importo della spesa."), 16)

			Return .F.

		EndCase

	EndIf



Case cControlSource = 'cd_cacda' Or cControlSource = 'cd_caformula'

	If !IsEmpty(Evaluate(oControl.Parent.Parent.RecordSource + '.Cd_CAFormula')) And ;

			!IsEmpty(Evaluate(oControl.Parent.Parent.RecordSource + '.Cd_CACda'))

		xMessageBox(Thisform.TB_(,'35EF5E74-1764-49A6-9802-61370A9FE10A', 'Non è possibile indicare nella stessa riga il centro di analisi e la formula di ripartizione.'))

		Return 0

	EndIf





Case cControlSource = 'importov'



	Select DORigSpesa

	If !IsEmpty(DORigSpesa.Id_DoRigSpesa_Evade) And ;

		oControl.Value > (DORigSpesa.DocEvaso_ImportoEvadibileV + DORigSpesa.ImportoEvasoV_InOrigine)

		If xMessageBox(Thisform.TB_(,'6322835C-4336-41B4-9C1D-36BD49096560', "L'importo indicato supera l'evadibile." + CRLF + "Impostare l'importo evaso uguale al massimo importo evadibile?"), MB_ICONQUESTION + MB_YESNO) == IDNO

			Return .F.

		EndIf

	EndIf



	If oControl.Value < 0

		xMessageBox(Thisform.TB_(,'4BD1EA0B-281E-4D72-AD16-32B1384D53CE', "L'importo delle spese non può essere negativo."), MB_ICONSTOP)

		Return .F.

	EndIf



Case cControlSource == 'cd_aliquota_e'



	** Avverto per eliminazione del codice di esenzione in documento evadente

	If !IsEmpty(xOldValue) And IsEmpty(oControl.Value)  And !IsEmpty(Dorigspesa.Id_Dorigspesa_Evade) And !IsNull(Thisform.DoIntento_Evade('S', DoRigSpesa.Id_Dorigspesa_Evade)) And ;

		xMessageBox(Thisform.TB_(,'80264B8A-D92C-468E-B1EC-68387D061368', ;

						"La riga è stata evasa da un documento cui è stata applicata lettera d'intento." + CRLF + ;

						"L'eliminazione del codice nel presente documento non effettua alcun aggiornamento del documento evaso." + CRLF + ;

						"Il plafond risulterà in ogni caso utilizzato in base a quanto dichiarato nel documento evaso." + CRLF + CRLF + ;

						"Procedo con la cancellazione del codice?"), MB_ICONQUESTION + MB_YESNO + MB_DEFBUTTON2) == IDNO



		oControl.SetValue(xoldValue)

		Return .F.

	EndIf



EndCase



ENDPROC

PROCEDURE modifycolumnslook

Local cDoAlias



Iif(Empty(THISFORM.PF.pgGenerale.txtCd_DO.Field.FKAlias), THISFORM.PF.pgGenerale.txtCd_DO.Field.Refresh(), .T.)



cDoAlias = ThisForm.PF.pgGenerale.txtCd_DO.Field.FKAlias



** ---------- RESET UI STATE



With This.cntFattura



.Grid.ColImportoEvadibileV.ResetToDefault('Visible')

.Grid.ColCd_CAVda.ResetToDefault('Visible')

.Grid.ColCd_CACda.ResetToDefault('Visible')

.Grid.ColCd_CAFormula.ResetToDefault('Visible')

.Grid.ColCAPartenza.ResetToDefault('Visible')

.Grid.ColCADurata.ResetToDefault('Visible')



.Grid.ColImportoV.Header1.ResetToDefault('Caption')

.Grid.ColDOIntento.ResetToDefault('Visible')



.Grid.ResetToDefault('Visible')

.Title.ResetToDefault('Visible')



.txtAcconto.ResetToDefault('Visible')

.TxtAbbuono.ResetToDefault('Visible')

.chkSpeseBolli.ResetToDefault('Visible')



EndWith



** ---------- RESET UI STATE



With This.cntFattura



.Grid.ColImportoEvadibileV.Visible	= Thisform.IsPrelevabile

.Grid.ColCd_CAVda.Visible				= &cDOAlias..CAEnabled

.Grid.ColCd_CACda.Visible				= &cDOAlias..CAEnabled

.Grid.ColCd_CAFormula.Visible			= &cDOAlias..CAEnabled

.Grid.ColCAPartenza.Visible				= &cDOAlias..CAEnabled

.Grid.ColCADurata.Visible				= &cDOAlias..CAEnabled



** Il periodo e la durata li visualizzo solo se è impostato a true il flag Preferenza.CACGPeriodo

If !Thisform.DE.Preferenza.CACGPeriodo

	.Grid.ColCAPartenza.Visible			= &cDOAlias..CAEnabled

	.Grid.ColCADurata.Visible			= &cDOAlias..CAEnabled



	.Grid.ColDataInizioComp.Visible		= .F.

	.Grid.ColDataFineComp.Visible		= .F.



Else

	.Grid.ColCAPartenza.Visible			= .F.

	.Grid.ColCADurata.Visible			= .F.

	

	.Grid.ColDataInizioComp.Visible		= .T.

	.Grid.ColDataFineComp.Visible		= .T.

EndIf





** DOCIVATI

.Grid.ColImportoV.Header1.Caption 	= 'Importo' + Iif(DoTes.ImportiIvati, ' Ivato', '')



** DICHINT

.Grid.ColDOIntento.Visible				= Thisform.DoIntento_Visible()



** le spese non sono gestite

.Grid.Visible 			 	= !DoTes.ImportiIvati

.Title.Visible 	 		= !DoTes.ImportiIvati

.chkSpeseBolli.Visible 	= !DoTes.ImportiIvati



** L'arrotondamento del netto a pagare inibisce l'utilizzo del campo abbuono in UI

.TxtAbbuono.Visible = IsEmpty(&cDOAlias..ArrotondamentoN)



** Nota Sola Iva

If &cDoAlias..FTE_NotaIva



	.Grid.Visible 			 					= .F.

	.Grid.Parent.Title.Visible 	 		= .F.

	.Grid.Parent.chkSpeseBolli.Visible 	= .F.

	.txtAcconto.Visible 						= .F.

	.txtAbbuono.Visible 						= .F.

	.chkSpeseBolli.Visible 					= .F.



EndIf



EndWith



**	** DOCIVATI: niente acconti fissi o abbuoni

**	This.cntFattura.txtAbbuono			.Visible = This.cntFattura.txtAbbuono.Visible And !DoTes.ImportiIvati

**	This.cntFattura.txtAcconto.Field1.Visible = !DoTes.ImportiIvati  

**	This.cntFattura.txtAcconto.Label1.Visible = !DoTes.ImportiIvati 



** Acconto e Abbuono non gestiti per fattura elettronica

** L'arrotondamento del netto a pagare inibisce l'utilizzo del campo abbuono in UI

** Thisform.PF.PgGenerale.PF.PgPiede.Cnt.CntFattura.TxtAbbuono.Visible = IsEmpty(&cDOAlias..ArrotondamentoN) And !DoTes.FatturaElettronica

** Thisform.PF.PgGenerale.PF.PgPiede.Cnt.CntFattura.txtAcconto.Visible = !DoTes.FatturaElettronica



Thisform.SetRegimeIva('COLSINTERFACE')





ENDPROC

PROCEDURE calcolapesovolume

Lparameters cField



Local cTmpTable

Local nWA, nRec, nTot



cTmpTable = ''

nWA = Select(0)



#If Version(5) >= 900



	** N.B.: Senza il cast ottengo dal prodotto un Numeric 36,16 che per VFP 

	**			diviene 20,16

	**			Il CursorToServer crea un tabella con Decimal(20,16) e poi

	**			nel trasferivi i dati con Bulkinsert si perde i numeri > 9999

	**			Bug subdolissimo!!!



	Select Cd_AR, Cast(Qta * FattoreToUM1 As Numeric(18,8)) As Qta	;

	From DoRig With (BUFFERING = .T.)			;

	Where !IsEmpty(Cd_AR)							;

	Into Cursor tmpRig



#Else

	Create Cursor tmpRig (Cd_AR C(20), Qta N(18,8))



	Select DoRig

	nRec = Recno('DORig')

    

	Scan For !IsEmpty(Cd_AR)

		Insert Into tmpRig (Cd_AR, Qta) Values (DORig.Cd_AR, DORig.Qta * DORig.FattoreToUM1)

	EndScan



	Locate Record nRec

#Endif



** Carico il cursore nel server...

CursorToServer('tmpRig', @cTmpTable)



** e faccio una select per avere la somma del valore richiesto (pesonetto, pesolordo, volume)

Text To cStmt NoShow Textmerge

	Select

		Sum(AR.<<cField>> * T.Qta) As Valore

	From

		AR Join <<cTmpTable>> T On AR.Cd_AR = T.Cd_AR Collate Database_Default

EndText

nTot = xSqlExec2Var(cStmt)



Use In tmpRig

Select (nWA)



Return Nvl(nTot, 0)



ENDPROC

PROCEDURE showschedatrasporto

Lparameters nDoBitMask



nDoBitMask = Evl(nDoBitMask, DoTes.DoBitMask)



If Bitand(nDoBitMask, TD_CA_BOLLA + TD_CA_FATTURA_ACC + TD_CP_BOLLA + TD_CP_RESOMERCE + TD_AD_TRASFERIMENTO) != 0

	With This.cntDDT

		.cntSdT.Visible = .T.	

		ObjMov(.txtSpedizione, 	.cntSdT.Left + .cntSdT.Width + 4, , 210)

		ObjMov(.txtPorto, 		.txtSpedizione.Left, 				 , 210)

		ObjMov(.txtAspettoBeni, .txtSpedizione.Left, 				 , 210)

	EndWith 

Else

	With This.cntDDT

		.cntSdT.Visible = .F.

		ObjMov(.txtSpedizione, 	.txtVettore1.Left, , .txtVettore1.Width)

		ObjMov(.txtPorto, 		.txtVettore1.Left, , .txtVettore1.Width)

		ObjMov(.txtAspettoBeni, .txtVettore1.Left, , .txtVettore1.Width)

	EndWith 

EndIf 

ENDPROC

PROCEDURE grid_when

LParameters oControl



Local cControlSource



cControlSource = AllTrim(Lower(oControl.ControlSource))

cControlSource = Iif(At('.', cControlSource) > 0, JustExt(cControlSource), cControlSource)		&& Ricavo solo Nome delField



Do Case



	Case cControlSource == 'cd_reversecharge'

	

		Return IsEmpty(Dorigspesa.Cd_RC)



	** ----- COAN Section ----- **



	Case cControlSource == 'cd_caformula'

	

		Return IsEmpty(DoRigSpesa.Cd_CACda)



	Case cControlSource == 'cd_cacda'

	

		Return IsEmpty(DoRigSpesa.Cd_CAFormula)

		

EndCase



Return .T.

ENDPROC

PROCEDURE calcolaspeseperc

** Lavora sul record corrente dell'alias passato

Lparameters cAlias



Local oDoTotali, nSpese



cAlias 		= Evl(cAlias, This.CntFattura.Grid.RecordSource)

oDoTotali 	= Thisform.TotaleDocumento()

nSpese		= Round(oDoTotali.TotMerceNettoV * &cAlias..Perc / 100, DoTes.Decimali)



Return NEvl(nSpese, 0)





ENDPROC

PROCEDURE setdorigspesa_defaults_di

** cScope = DEF; FOR



Lparameters cScope



Local oData, cOldkey



** EXIT: Non è applicabile la dichiarazione

** EXIT: non è specificato alcune codice iva

** EXIT: esiste una dichiarazione sulla riga evasa

** EXIT: Non è dichiarato il CF

** EXIT: Non è indicato il cambio

** EXIT: Non si applica ai doc non esecutivi se non è richiesta inclusione esplicita (DO.DIExecutive)



** In assenza di codice iva elimino anche quello per dichiarazione intento

If IsEmpty(DoRigSpesa.Cd_Aliquota) And !IsEmpty(DoRigSpesa.Cd_Aliquota_e)

	Replace Cd_Aliquota_e With Null In DoRigSpesa

EndIf 



If !Thisform.DoIntento Or ;

	IsEmpty(DoRigSpesa.Cd_Aliquota) Or ;

	IsEmpty(Substr(NEvl(Dotes.Cd_CF_Fatt, Dotes.Cd_CF), 2)) Or ;

	IsEmpty(Dotes.Cambio) Or ;

	!IsNull(Thisform.DoIntento_Evade('S', DoRigSpesa.Id_Dorigspesa_Evade)) Or ;

	(!Dotes.Esecutivo And !Dotes.DIExecutive) Or ;

	(DoTes.DISave And Bitand(Thisform.Mode, FEDIMODE_INS_DUP) != 0)

	Return .T.

EndIf



cScope = Upper(xDefault(cScope, 'DEF'))



** Non considero la riga corrente come dato da passare nel buffer

Replace DoIntento With Null In Dorigspesa



** Mi serve l'importo in euro

Replace ImportoE With Round(DorigSpesa.ImportoV / Dotes.Cambio, 2) in Dorigspesa



oData = Thisform.oDointento.Get_Aliquota( ;

	  NEvl(Dotes.Cd_CF_Fatt, Dotes.Cd_CF) ;

	, Dotes.Cd_DO ;

	, Null ;

	, DorigSpesa.Cd_Aliquota ;

	, DorigSpesa.Cd_ReverseCharge ;

	, NEvl(Iif(Dotes.Clifor == 'F', Dotes.DataDocRif, Null), Dotes.DataDoc) ;

	, Iif(cScope == 'DEF' Or (IsEmpty(DoRigSpesa.ImportoE) And !IsEmpty(DoRigSpesa.Perc)), Evl(Round(This.CalcolaSpesePerc() / Dotes.Cambio, 2), 1), DorigSpesa.ImportoE) ;

	, Dotes.ImportiIvati ;

	, Dotes.Esecutivo ;

	, Null ;

	, DorigSpesa.Id_DoRigSpesa_Evade ;

	, Iif(cScope == 'DEF', Null, Thisform.oDointento.Get_Buffer_Esclude('DORIG', 'DORIGSPESA', 0, .F., .T.)) ;

	, Iif(cScope == 'DEF', Null, Thisform.oDointento.Get_Buffer_Edit('DORIG', 'DORIGSPESA', 0, .F., .F.)))



If Vartype(oData) = 'O'



	If Thisform.oDoIntento.WrkEnabled

		cOldkey = Thisform.oDoIntento.Wrk_GetKey(DoRigSpesa.DoIntento)

		oData.ExtraInfo = Thisform.oDoIntento.Wrk_SetKey(oData.ExtraInfo, cOldkey)

	EndIf

			

	Replace ;

		Cd_Aliquota_e 	With oData.Cd_Aliquota_e ;

		Cd_Aliquota_r 	With oData.Cd_Aliquota_r ;

		DoIntento		With Iif(cScope == 'DEF', Null, oData.ExtraInfo) ;

		DoIntentoCode	With Iif(cScope == 'DEF', Null, oData.ErrorCode) ;

		In DorigSpesa



	Iif(Thisform.oDoIntento.WrkEnabled, Thisform.oDoIntento.Wrk_Update(DoRigspesa.DoIntento), .T.)

	

EndIf



ENDPROC

PROCEDURE setdorigspesa_defaults_iva

Lparameters oRec



**	oRec = FKRECORD -> In mancanza rilevo il record da Dorig.Cd_Aliquota_r



** Viene richiamato in POSTFORMULAE una sola volta in modo accentrato

Replace Cd_Aliquota_r With Nevl(DoRigspesa.Cd_Aliquota_e, DoRigspesa.Cd_Aliquota) In DoRigspesa



oRec = Iif(Vartype(oRec) != 'O', xSqlExec2Obj(Textmerge('Select * From Aliquota Where Cd_aliquota = <<FormatC4Spt(DoRigspesa.Cd_Aliquota_r)>>'), .T.), oRec)



Replace ;

	IvaMoss			With oRec.Ivamoss ;

	IvaSplit			With oRec.IvaSplit ;

	Iva_Split_Sep	With (oRec.Iva_Split_Sep And DoTes.Clifor != 'C') ;

	Cd_RC				With oRec.Cd_ReverseCharge ;

In DoRigspesa



Iif(!PemStatus(This, 'RC_OnValueChange', 5), AddProperty(This, 'RC_OnValueChange', .F.), .T.)

Iif(!PemStatus(This, 'IVA_OnValueChange', 5), AddProperty(This, 'IVA_OnValueChange', .F.), .T.)



Iif(This.RC_OnValueChange Or !This.IVA_OnValueChange, Thisform.SetRegimeIva('ONEROW+S-RC'), Thisform.SetRegimeIva('ONEROW+S'))



AddProperty(This, 'RC_OnValueChange', .F.)

AddProperty(This, 'IVA_OnValueChange', .F.)



ENDPROC

PROCEDURE Init

Lparameters oPage



DoDefault(oPage)



** Bug 508

** Venendo istanziati esternamente i controlli non hanno ancora fatto

** il refresh() e quindi FKALIAS non era valorizzato

If Empty(Thisform.PF.pgGenerale.txtCd_DO.Field.FKAlias)

	Thisform.PF.pgGenerale.txtCd_DO.Field.Refresh()

Endif

*******************************************



This.CntFattura.Grid.AllowAddNew	= (Thisform.Mode != FEDIMODE_SHOW)

This.CntFattura.Grid.InitAutoSaveLayout()



** ----- LICADAPTER

With This.CntFattura.Grid



	If !oApp.LicInfo.Commesse

		.ColCd_SottoCommessa.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

	Endif



	If !oApp.LicInfo.CA_Main

		.ColCd_CAVda.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

		.ColCd_CACda.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

		.ColCd_CAFormula.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

		.ColCAPartenza.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

		.ColCADurata.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

	Endif



Endwith



This.ShowSchedaTrasporto()



*******************************************



If !InArtel() Or !Used('DoUiCfg') Or Eof('DoUiCfg')

	Return

Endif



If DoUiCfg.PaginaPiede

	If !DoUiCfg.PiedeDatiDDT

		Thisform.PF.pgGenerale.PF.pgPiede.Cnt.cntDDT.Visible = .F.

	Endif

	If !DoUiCfg.PiedeDatiFattura

		Thisform.PF.pgGenerale.PF.pgPiede.Cnt.CntFattura.Visible = .F.

	Endif

Endif



ENDPROC


*======================================================================

*** CLASS / OBJECT: btnSommaPesoLordo (BaseClass: commandbutton, Parent: pgpiede.cntDDT.txtPesoLordo) ***
*** PROPERTIES ***
Comment = "080478E9-F07E-4FFD-9BAB-4357B46186A7"

Top = -1

Left = 171

Height = 21

Width = 21

Anchor = 8

Picture = ..\images\included\sum.bmp

Caption = ""

ToolTipText = "Calcola il peso lordo totale"

Name = "btnSommaPesoLordo"


*** METHODS ***
PROCEDURE Click

If Thisform.Mode = FEDIMODE_SHOW

	Return

EndIf 



This.Parent.Field.Value = This.Parent.Parent.Parent.CalcolaPesoVolume('PesoLordoMks')

ENDPROC


*======================================================================

*** CLASS / OBJECT: btnSommaPesoNetto (BaseClass: commandbutton, Parent: pgpiede.cntDDT.txtPesoNetto) ***
*** PROPERTIES ***
Comment = "701AFFCB-20EE-4125-894C-711DF31EF033"

Top = -1

Left = 171

Height = 21

Width = 21

Anchor = 8

Picture = ..\images\included\sum.bmp

Caption = ""

ToolTipText = "Calcola il peso netto totale"

Name = "btnSommaPesoNetto"


*** METHODS ***
PROCEDURE Click

If Thisform.Mode = FEDIMODE_SHOW

	Return

EndIf 



This.Parent.Field.Value = This.Parent.Parent.Parent.CalcolaPesoVolume('PesoNettoMks')

ENDPROC


*======================================================================

*** CLASS / OBJECT: btnSommaVolume (BaseClass: commandbutton, Parent: pgpiede.cntDDT.txtVolume) ***
*** PROPERTIES ***
Comment = "227A74FB-BEAF-42A8-8F1A-D38FBAFD939B"

Top = -1

Left = 163

Height = 21

Width = 21

Anchor = 8

Picture = ..\images\included\sum.bmp

Caption = ""

ToolTipText = "Calcola il volume totale"

Name = "btnSommaVolume"


*** METHODS ***
PROCEDURE Click

If Thisform.Mode = FEDIMODE_SHOW

	Return

EndIf 



This.Parent.Field.Value = This.Parent.Parent.Parent.CalcolaPesoVolume('VolumeMKS')

ENDPROC


*======================================================================

*** CLASS / OBJECT: btnSommaColli (BaseClass: commandbutton, Parent: pgpiede.cntDDT.txtColli) ***
*** PROPERTIES ***
Comment = "BCC4A604-F762-491F-AEED-2D2B900745C8"

Top = -1

Left = 111

Height = 21

Width = 21

Anchor = 8

Picture = ..\images\included\sum.bmp

Caption = ""

ToolTipText = "Calcola il numero di colli totale"

Name = "btnSommaColli"


*** METHODS ***
PROCEDURE Click

Local i, n, nWA, nRec, nTot

Local cFilter, cLastPack

Local aPackList[1]



i 	 = 0



If Thisform.Mode = FEDIMODE_SHOW Or !Evaluate(ThisForm.PF.pgGenerale.txtCd_DO.FIELD.FKAlias+ '.PkLstEnabled')

	Return

EndIf 



nWA = Select(0)



Select DORig		&& mi salvo la posizione del record corrente di DORig

nRec = Recno()



If Evaluate(ThisForm.PF.pgGenerale.txtCd_DO.FIELD.FKAlias+ '.PkLstMode') = 1 			&& pack singolo



	** --------------------------------------------------------------------------

	** Per ogni riga (valida) di DORig metto in un array il riferimento del collo



	Scan

		i = i + 1

		Dimension aPackList[i]

		aPackList[i] = DORig.PackListRef

	EndScan	

	

Else																											&& più codice per riga

	

	** -----------------------------------------

	** Controllo se ho i dati di packing list...



	Select DoRigPackList			

	cFilter = Set("Filter")

	Set Filter To

	Count to n



	** -----------------------------------------

	** Se non li ho, li chiedo al server...	



	If n = 0							

		Thisform.DE.DoRigPackList.Requery( 'DORig.Id_DOTes = ' + Format4Spt(DOTes.Id_DOTes))

		Thisform.DE.DoRigPackList.Buffering = 3

		Thisform.DE.DoRigPackList.MakeIndex('PackListRef', 'Elemento')

		Thisform.DE.DoRigPackList.MakeIndex('Id_Dorig')

		Thisform.DE.DoRigPackList.MakeIndex('Riga')

		Thisform.DE.DoRigPackList.Buffering = 5

	EndIf 



	Set Filter To &cFilter

	Go Top In DoRigPackList



	** -------------------------------------------------------------------------------

	** Per ogni riga (valida) di DORig metto in un array tutti i riferimenti dei colli



	Select DoRig

	Scan

		Select DoRigPackList

		Scan

			i = i + 1

			Dimension aPackList[i]

			aPackList[i] = DORigPackList.PackListRef

		EndScan 

	EndScan



EndIf



Select DoRig				&& riposiziono DORig

Locate Record (nRec)



** ------------------------------------------------------------

** Conto quanti colli sono stati utilizzati, escludendo i doppi



Asort(aPackList)



cLastPack = Null

nTot = 0

For i = 1 to Alen(aPackList)

	If !IsEmpty(aPackList[i]) And !SafeCompare(cLastPack, aPackList[i])

		cLastPack = aPackList[i]	

		nTot = nTot + 1

	EndIf 

EndFor



This.Parent.Field.Value = nTot



Select (nWA)





ENDPROC


*======================================================================

*** CLASS / OBJECT: cntSdT (BaseClass: container, Parent: pgpiede.cntDDT) ***
*** PROPERTIES ***
Top = 83

Left = 0

Width = 208

Height = 63

BorderWidth = 0

TabIndex = 5

Name = "cntSdT"


*** METHODS ***
PROCEDURE Init

Local oRec, oBmp, oGfx

Local cTmpFile



DoDefault()



** --------------------------------------------------



With oGDI.System.Drawing

	oRec  = .Rectangle.New(0, 0, Sysmetric(1) * 2, This.Height)

	oBmp  = .Bitmap.New(oRec)

	oGfx  = .Graphics.FromImage(oBmp)

	oGfx.FillRectangle(.Brushes.Lavender, oRec)

Endwith



cTmpFile = oApp.TmpDir + '\' + Sys(2015) + '.bmp'

Strtofile(oBmp.GetPictureValfromHBitmap(), cTmpFile)

This.Picture = cTmpFile

ENDPROC


*======================================================================

*** CLASS / OBJECT: txtCommittente (BaseClass: textbox, Parent: pgpiede.cntDDT.cntSdT) ***
*** PROPERTIES ***
ControlSource = "dotes.cd_docommittente"

Format = "!"

Left = 140

TabIndex = 3

ToolTipText = "Committente"

Top = 1

Width = 35

ZOrderSet = 16

fkselect = SELECT * FROM DOSdTAnag WHERE Left(Cd_DOSdTAnag, 1) = '2' And Cd_DOSdTAnag = <TEXT>

fkfediform = Fedi_DOCommittente

fktabledesc = Committente

fkdecodedfield = Descrizione

Name = "txtCommittente"


*** METHODS ***
PROCEDURE fkshowdescription

LParameters cDescText



DoDefault(cDescText)

This.ToolTipText = RTrim(cDescText)



ENDPROC


*======================================================================

*** CLASS / OBJECT: txtCaricatore (BaseClass: textbox, Parent: pgpiede.cntDDT.cntSdT) ***
*** PROPERTIES ***
ControlSource = "dotes.cd_docaricatore"

Format = "!"

Left = 103

TabIndex = 2

ToolTipText = "Caricatore"

Top = 1

Width = 35

ZOrderSet = 16

fkselect = SELECT * FROM DOSdTAnag WHERE Left(Cd_DOSdTAnag, 1) = '1' And Cd_DOSdTAnag = <TEXT>

fkfediform = Fedi_DOCaricatore

fktabledesc = Caricatore

fkdecodedfield = Descrizione

Name = "txtCaricatore"


*** METHODS ***
PROCEDURE fkshowdescription

LParameters cDescText



DoDefault(cDescText)

This.ToolTipText = RTrim(cDescText)



ENDPROC


*======================================================================

*** CLASS / OBJECT: txtProprietarioMerce (BaseClass: textbox, Parent: pgpiede.cntDDT.cntSdT) ***
*** PROPERTIES ***
ControlSource = "dotes.cd_doproprietariomerce"

Format = "!"

Left = 103

TabIndex = 9

ToolTipText = "Proprietario della merce"

Top = 43

Width = 35

ZOrderSet = 16

fkselect = SELECT * FROM DOSdTAnag WHERE Left(Cd_DOSdTAnag, 1) = '3' And Cd_DOSdTAnag = <TEXT>

fkfediform = Fedi_DOProprietarioMerce

fktabledesc = Proprietario Merce

fkdecodedfield = Descrizione

Name = "txtProprietarioMerce"


*** METHODS ***
PROCEDURE fkshowdescription

LParameters cDescText



DoDefault(cDescText)

This.ToolTipText = RTrim(cDescText)



ENDPROC


*======================================================================

*** CLASS / OBJECT: txtLuogoScar (BaseClass: textbox, Parent: pgpiede.cntDDT.cntSdT) ***
*** PROPERTIES ***
ControlSource = "dotes.cd_doluogoscarico"

Format = "!"

Left = 140

TabIndex = 7

ToolTipText = "Luogo di scarico"

Top = 22

Width = 35

ZOrderSet = 16

fkselect = SELECT * FROM DOSdTAnag WHERE Left(Cd_DOSdTAnag, 1) = '4' And Cd_DOSdTAnag = <TEXT>

fkfediform = Fedi_DOLuogoCarico

fktabledesc = LuogoScar

fkdecodedfield = Descrizione

Name = "txtLuogoScar"


*** METHODS ***
PROCEDURE fkshowdescription

LParameters cDescText



DoDefault(cDescText)

This.ToolTipText = RTrim(cDescText)



ENDPROC


*======================================================================

*** CLASS / OBJECT: txtLuogoCar (BaseClass: textbox, Parent: pgpiede.cntDDT.cntSdT) ***
*** PROPERTIES ***
ControlSource = "dotes.cd_doluogocarico"

Format = "!"

Left = 103

TabIndex = 6

ToolTipText = "Luogo di carico"

Top = 22

Width = 35

ZOrderSet = 16

fkselect = SELECT * FROM DOSdTAnag WHERE Left(Cd_DOSdTAnag, 1) = '4' And Cd_DOSdTAnag = <TEXT>

fkfediform = Fedi_DOLuogoCarico

fktabledesc = LuogoCar

fkdecodedfield = Descrizione

Name = "txtLuogoCar"


*** METHODS ***
PROCEDURE fkshowdescription

LParameters cDescText



DoDefault(cDescText)

This.ToolTipText = RTrim(cDescText)



ENDPROC


*======================================================================

*** CLASS / OBJECT: btnAltro (BaseClass: commandbutton, Parent: pgpiede.cntDDT.cntSdT) ***
*** PROPERTIES ***
Comment = "29967643-851A-4635-9D44-879110185407"

Top = 42

Left = 140

Height = 21

Width = 67

Caption = "Altro SdT"

TabIndex = 10

Name = "btnAltro"


*** METHODS ***
PROCEDURE Click

Local oForm



oForm = FNewObjectWCR('SdTAltro', 'Forms\Fedi_DocCommon.vcx',, DoTes.SdTAltro, Thisform.Mode = FEDIMODE_SHOW)

oForm.Show(1)

If oForm.WasConfirmed

	Replace SdTAltro With oForm.XmlResult In DoTes

EndIf 

oForm.Release()

ENDPROC


*======================================================================

*** CLASS / OBJECT: Cmbtipospesa1 (BaseClass: combobox, Parent: pgpiede.CntFattura.Grid.ColTipoRigaSpesa) ***
*** PROPERTIES ***
Comment = "63312284-510A-46A8-8706-A1006CD1CAEE"

FontSize = 8

Left = 659

SpecialEffect = 1

Top = 13

Name = "Cmbtipospesa1"


*** METHODS ***
PROCEDURE onvaluechange

LParameters xOldValue



Local oRec



DoDefault(xOldValue)



oRec = DoRigSpesa_Defaults_AliquotaConto_2Obj(This.Value, DOTes.Cd_DO, DOTes.Cd_CF, DOTes.Cd_CFDest)



This.Parent.Parent.colDescrizione.Text1.SetValue('Spese ' + This.List(This.ListIndex, 1))

This.Parent.Parent.colCd_Aliquota.stdText1.SetValue(Nvl(oRec.Cd_Aliquota, ''))

This.Parent.Parent.colCd_CGConto.spcConto1.SetValue(Nvl(oRec.Cd_CGConto, ''))



This.Parent.Parent.colDescrizione.Refresh()

This.Parent.Parent.colCd_Aliquota.Refresh()

This.Parent.Parent.colCd_CGConto.Refresh()



If IsNull(oRec.Cd_Aliquota) Or IsNull(oRec.Cd_CGConto)

	Local cMessage, lCliente

	

	lCliente = Evaluate(ThisForm.PF.pgGenerale.txtCd_DO.Field.FKAlias + '.CliFor') = 'C'

	

	cMessage = Thisform.TB_(,'6E239B7F-A888-4877-897D-D9EED217AD46', 'I seguenti dati non sono stati configurati nelle impostazioni per Spese %1!:' + CRLF , This.List(This.ListIndex, 1))

	If IsNull(oRec.Cd_Aliquota)

		If lCliente

			cMessage = cMessage + CRLF + '  - ' + Thisform.TB_(,'4ADD9F28-6395-48BC-960F-018C25A53053', 'Codice IVA Ricavo') 

		Else

			cMessage = cMessage + CRLF + '  - ' + Thisform.TB_(,'021CD01C-29C6-4C56-A4F6-1F33310C9B6E', 'Codice IVA Costo') 		

		EndIf 

	EndIf 



	If IsNull(oRec.Cd_CGConto)

		If lCliente

			cMessage = cMessage + CRLF + '  - ' + Thisform.TB_(,'99ECE2F3-639E-4F93-9B32-B4E81EF35DB6', 'Codice Conto Ricavo')

		Else

			cMessage = cMessage + CRLF + '  - ' + Thisform.TB_(,'E528C541-8DF4-4CDE-ADAF-BCE8A13F41C9', 'Codice Conto Costo') 		

		EndIf 

	EndIf 



	xMessagebox(cMessage)

EndIf





ENDPROC


*======================================================================

*** CLASS / OBJECT: StdText1 (BaseClass: textbox, Parent: pgpiede.CntFattura.Grid.ColCd_Aliquota) ***
*** PROPERTIES ***
FontSize = 8

BorderStyle = 0

Format = "!"

Margin = 0

Top = 11

Width = 25

fkselect = SELECT * FROM Aliquota WHERE Cd_Aliquota = <TEXT> And IvaSplit = 0

fkdecodedfield = Descrizione

Name = "StdText1"


*** METHODS ***
PROCEDURE fkselect_access

Return 	This.FKSelect + ;

			Iif(!Thisform.IvaMoss_Set(), ' And Aliquota.IvaMoss = 0', '')



ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



DoDefault(xOldValue)



AddProperty(This.parent.parent.parent.parent, 'IVA_OnValueChange', .T.)

This.parent.parent.parent.parent.Setdorigspesa_Defaults_IVA()



ENDPROC


*======================================================================

*** CLASS / OBJECT: Spcconto1 (BaseClass: textbox, Parent: pgpiede.CntFattura.Grid.ColCd_CGConto) ***
*** PROPERTIES ***
FontSize = 8

BorderStyle = 0

Left = 38

Margin = 0

Top = 59

Name = "Spcconto1"


*** METHODS ***
PROCEDURE onvaluechange

LParameters xOldValue



Local cDOAlias, oRec, oDef 



** Default per CA

cDOAlias = ThisForm.PF.pgGenerale.txtCd_DO.Field.FKAlias

If &cDOAlias..CAEnabled

	

	oRec = DoRig_Defaults_CA_2Obj(DOTes.Cd_DO, DOTes.Cd_CF, DOTes.Cd_CFDest, Null, DoRigSpesa.Cd_CGConto)

	With This	

		.Parent.Parent.colCd_CAVda.spcCAVda1.SetValue(oRec.Cd_CAVda)

		.Parent.Parent.colCd_CACda.spcCACda1.SetValue(oRec.Cd_CACda)

		.Parent.Parent.colCd_CAFormula.Text1.SetValue(oRec.Cd_CAFormula)

		.Parent.Parent.colCAPartenza.Text1.SetValue(oRec.CAPartenza)

		.Parent.Parent.colCADurata.Text1.SetValue(oRec.CADurata)

	EndWith	

	

	If Thisform.DE.Preferenza.CACGPeriodo

		oDef = RR_GetDefaults_DO(DoTes.Cd_DO, DoRigSpesa.Cd_CGConto, DOTes.DataDoc)

		With This				

			.Parent.Parent.ColDataInizioComp.Stdtext1.SetValue(oDef.RR_DataInizio)

			.Parent.Parent.ColDataFineComp.Stdtext1.SetValue(oDef.RR_DataFine)

		EndWith	

	EndIf

	

EndIf



ENDPROC


*======================================================================

*** CLASS / OBJECT: Spccacda1 (BaseClass: textbox, Parent: pgpiede.CntFattura.Grid.ColCd_CACda) ***
*** PROPERTIES ***
FontSize = 8

BorderStyle = 0

Left = 37

Margin = 0

Top = 62

Name = "Spccacda1"


*** METHODS ***
PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If Empty(DoDefault(lIsChanged, xOldValue))

	Return .F.

Endif



If lIsChanged

	Return This.Parent.Parent.Parent.Parent.Grid_IsValid(This, .F., xOldValue)

Else

	Return .T.

Endif



ENDPROC


*======================================================================

*** CLASS / OBJECT: Stdedit1 (BaseClass: editbox, Parent: pgpiede.CntFattura.Grid.ColRigaSpesa_Evasa) ***
*** PROPERTIES ***
Comment = "60D41D5A-D101-4DE9-A353-6EA9E975CB87"

FontSize = 8

BorderStyle = 0

Left = 45

Margin = 0

ReadOnly = .T.

Top = 36

Name = "Stdedit1"


*** METHODS ***
PROCEDURE readonly_assign

LPARAMETERS vNewVal

DODEFAULT(.T.)

ENDPROC


*======================================================================

*** CLASS / OBJECT: PF (BaseClass: pageframe, Parent: fedi.PF.pgGenerale) ***
*** PROPERTIES ***
ErasePage = .T.

PageCount = 7

Comment = "4FFAE9C8-3612-4C82-AED9-36CE93EB4129"

Anchor = 15

ActivePage = 1

Top = 37

Left = 1

Width = 649

Height = 389

TabIndex = 10

ZOrderSet = 0

Name = "PF"

Stdpage1.Comment = "6A5F6739-0806-405E-9397-99976AB732D0"

Stdpage1.Caption = "Testa"

Stdpage1.PageOrder = 1

Stdpage1.Name = "pgGenerale"

Stdpage2.Comment = "EC77D3FA-4C54-4A93-96A9-A3D6151BB835"

Stdpage2.Caption = "Righe"

Stdpage2.PageOrder = 2

Stdpage2.Name = "pgRighe"

Stdpage3.Comment = "7DA35306-FF6E-4EB4-A84E-02C3A6FC739C"

Stdpage3.Caption = "Piede"

Stdpage3.PageOrder = 3

Stdpage3.Name = "pgPiede"

Stdpage4.Comment = "23741D04-1271-463E-A485-0870FB158903"

Stdpage4.Caption = "Totali"

Stdpage4.PageOrder = 4

Stdpage4.Name = "pgTotali"

Stdpage5.Comment = "63A15B1C-473A-4DE9-99FB-D2500F43759E"

Stdpage5.Caption = "Evasioni"

Stdpage5.PageOrder = 6

Stdpage5.Name = "pgEvasioni"

Stdpage6.Comment = "7F3D5E6C-22A4-4AED-919C-9FB93AD28F9D"

Stdpage6.Caption = "Stampe"

Stdpage6.PageOrder = 7

Stdpage6.Name = "pgmoduli"

Stdpage7.Caption = "Info"

Stdpage7.PageOrder = 5

Stdpage7.Name = "pgInfo"


*** METHODS ***
PROCEDURE dynamicpageinitall

Lparameters lForce



Local i 

Local oPage



For i =  1 To This.PageCount 

 	oPage = This.Pages[i]

 	*Activate Screen

 	*? i, opage.name

	If oPage.ControlCount = 0 And (lForce Or PemStatus(oPage, 'IgnoreDynamicPageInitAll', 5) = .F. Or oPage.IgnoreDynamicPageInitAll = .F.)

		This.DynamicPageInit(oPage)			

	Endif

Next



ENDPROC

PROCEDURE onpageactivate

LParameters oPage, nOldPage,lJustRefreshed



DoDefault(oPage, nOldPage,lJustRefreshed)



Iif(Lower(oPage.Name) == 'pgrighe', oPage.Cnt.ModifyColumnsLook(), .T.)

Iif(Lower(oPage.Name) == 'pgpiede', oPage.Cnt.ModifyColumnsLook(), .T.)



ThisForm.Toolbar.Buttons('DELETE').Enabled 		=  InList(Lower(oPage.Name), 'pggenerale', 'pgtotali')

ThisForm.Toolbar.Buttons('DELETE').MixedState 	= !InList(Lower(oPage.Name), 'pggenerale', 'pgtotali')



** lNotInShowMode = (ThisForm.Mode != FEDIMODE_SHOW)

**	.Buttons('ROWADD').Visible = LOWER(oPage.Name) == 'pgmoduli' OR lNotInShowMode

**	.Buttons('ROWDEL').Visible = LOWER(oPage.Name) == 'pgmoduli' OR lNotInShowMode



ENDPROC

PROCEDURE dynamicpageinit

LParameters oPage

Local cPageName



cPageName = Lower(oPage.Name)

If oPage.ControlCount = 0



	** E' vero che il chiamante di questo metodo è l'OnPageActivate() che testa proprio questa condizione

	** prima di chiamare questo metodo, ma se il metodo viene sovrascritto da una pers

	**	che istanzia la pagina e poi fa dodefault avrei problemi se non rieseguo il test.



	If InList(cPageName, 'pgrighe', 'pgrighe', 'pgpiede', 'pgevasioni', 'pgarlotto', 'pgarimg', 'pgmoduli', 'pgtotali')

		MNewobjectWCR1(oPage, 'cnt', cPageName, ThisForm.ClassLibrary, '', oPage)

	EndIf



EndIf 



Do Case

	** Pagine del pageframe generale

	Case cPageName == 'pggenerale'

		.Cnt.PF.RefreshAllPages = (This.Mode != FEDIMODE_SHOW)



	** Pagine del pageframe nella page pgGenerale

	Case cPageName == 'pgrighe'

		ThisForm.SetPictureQta()

		oPage.Cnt.ModifyColumnsLook()

		

	** Pagine del pageframe nella page pgGenerale

	Case cPageName == 'pgpiede'

		oPage.Cnt.ModifyColumnsLook()



	Case cPageName == 'pgmoduli'

		oPage.Cnt.Grid.SetAll('ReadOnly', .F.)



EndCase



ThisForm.SetPictureValuta()



ENDPROC

PROCEDURE zoom_doaction

DoDefault()



** serve per far scattare lo zoom delle page righe e piede nel DynamicPageInit

This.AddProperty('MinPageWidth',  This.PageWidth) 

This.AddProperty('MinPageHeight', This.PageHeight) 

ENDPROC

PROCEDURE pgGenerale.Init

DoDefault()



If oApp.LicInfo.DO_Factoring And oApp.oUser.AccessFactoring And (Bitand(Thisform.DOBitMask,0x0000000008) > 0 Or Bitand(Thisform.DOBitMask,0x0000000010) > 0)

	MNewObjectWCR(This, 'cntFactoring', 'cntFactoring', 'Forms\Fedi_Doc.vcx')

	ObjMov(This.cntFactoring, This.cntConservazioneInvio.Left, This.cntConservazioneInvio.Bottom + 4,,, 11)

	This.cntFactoring.Visible = .T.

EndIf 

ENDPROC

PROCEDURE pgTotali.Init

This.AddProperty('IgnoreDynamicPageInitAll', .T.)

DoDefault()

ENDPROC

PROCEDURE pgEvasioni.Init

This.AddProperty('IgnoreDynamicPageInitAll', .T.)

DoDefault()

ENDPROC


*======================================================================

*** CLASS / OBJECT: cntConservazioneInvio (BaseClass: container, Parent: fedi.PF.pgGenerale.PF.pgGenerale) ***
*** PROPERTIES ***
Anchor = 11

Top = 208

Left = 2

ZOrderSet = 1

Name = "cntConservazioneInvio"

lblStatus.Name = "lblStatus"

TITLE.Height = 19

TITLE.Left = 0

TITLE.Top = 0

TITLE.Name = "TITLE"

imgConservato.Name = "imgConservato"

imgOperazioni.Height = 24

imgOperazioni.Width = 24

imgOperazioni.Name = "imgOperazioni"

imgStatus.Name = "imgStatus"

Line1.Name = "Line1"

Line2.Name = "Line2"


*** METHODS ***
PROCEDURE Refresh

DoDefault()



** Il cntConservazioneInvio è visibile solo per le FTE o documenti con autoarchiviazione

If Bitand(Thisform.Mode, FEDIMODE_INS_DUP) = 0 And (!IsNull(DOTes.FTE_Status) Or DoTes.AutoArchivia)

	This.Visible = .T.

Else

	This.Visible = .F.

EndIf 



Thisform.ShowHidePeppol(.T.) 

ENDPROC


*======================================================================

*** CLASS / OBJECT: cntStato (BaseClass: container, Parent: fedi.PF.pgGenerale.PF.pgGenerale) ***
*** PROPERTIES ***
Anchor = 8

Top = 208

Left = 273

Width = 102

Height = 78

BorderWidth = 0

TabIndex = 6

ZOrderSet = 5

Name = "cntStato"


*** METHODS ***
PROCEDURE Refresh

DoDefault()



This.imgModificabileImmaginePdf.TooltipText = "L'immagine PDF del documento" + Iif(DoTes.ModificabilePdf, " è modificabile.", " risulta bloccata.")

This.imgModificabileImmaginePdf.PictureRes  = "Images\ModificabilePdf_"      + Iif(DoTes.ModificabilePdf, "true", "false") + ".bmp@Forms\Fedi_Doc.rll"

PictureRes2Picture(This.imgModificabileImmaginePdf)



ENDPROC


*======================================================================

*** CLASS / OBJECT: chkEsecutivo (BaseClass: checkbox, Parent: fedi.PF.pgGenerale.PF.pgGenerale.cntStato) ***
*** PROPERTIES ***
Comment = "0DA95A9F-54B3-488D-BCA6-34941583E15D"

Top = 37

Left = 2

Height = 16

Width = 65

Alignment = 0

Caption = "Esecutivo"

Value = .F.

ControlSource = "DOTES.Esecutivo"

TabIndex = 2

ToolTipText = "Impostare questo flag per generare un documento Esecutivo; un documento NON Esecutivo non genera alcun tipo di movimento, non gestisce aspetti contabili e non può essere evaso"

Name = "chkEsecutivo"


*** METHODS ***
PROCEDURE onvaluechange

LPARAMETERS xOldValue



DoDefault(xOldValue)



** Applico nuovi criteri di esenzione indipendentemente dall'applicazione dei nuovi default

** Se cambia lo stato ed è richiesto di non applicare ai non esecutivi avviso l'utente che verrà applicata/rimossa la DI

** Se vengono considerati anche i documenti non esecutivi allora il cambio di stato non influenza l'applicazione

** Non applico nel caso che sia impostato il salvataggio alla fine (solo per ins)



If !SafeCompare(xOldValue, This.Value) And Thisform.DoIntento And !DoTes.DIExecutive ;

	And (!DoTes.DISave Or Bitand(Thisform.Mode, FEDIMODE_INS_DUP) = 0)



	Local nCount_R, nCount_S

	

	Calculate Cnt() For PrezzoTotaleV != 0 To nCount_R In Dorig

	Calculate Cnt() For ImportoV != 0 To nCount_S In Dorigspesa

	

	Go Top In Dorig

	Go Top In Dorigspesa

	

	If (nCount_R + nCount_S) > 0



		** Passando da .F. a .T. avviso che sarà applicata la DI

		Iif(!xOldValue And This.Value, xMessageBox(Thisform.TB_(,'58B72323-E1EF-41DB-832B-A32AE057F655', "Il documento esecutivo prevede applicazione di esenzione per lettera d'intento." + Chr(13) + "Verrà ricalcolata in base alla dichiarazione corrente."), MB_ICONINFORMATION), .T.)



		** Passando da .T. a .F. avviso che sarà rimossa la DI

		Iif(xOldValue And !This.Value, xMessageBox(Thisform.TB_(,'62F8FAD4-8A8C-481A-8097-D119052022BD', "Il documento non esecutivo non prevede applicazione di esenzione per lettera d'intento." + Chr(13) + "Verrà rimosso il codice di esenzione dalle righe del documento."), MB_ICONINFORMATION), .T.)

		

		** Ripulisco i dati per dichiarazione intento se cambio anagrafica

		Thisform.DoIntento_Clear()



		** Riapplico con il nuovo stato (se esecutivo .F. non viene applicato nulla)

		Thisform.DoIntento_Apply()

	

	EndIf

		

EndIf





ENDPROC

PROCEDURE onrefresh

LParameters xOldValue



This.Parent.chkPrelevabile.Enabled =  This.Value		&& Un documento può essere Prelevabile solo se è esecutivo.



ENDPROC

PROCEDURE Init

Text To This.ToolTipText

Togliere la spunta per rendere "Non Esecutivo" il documento.

Un documento "Non Esecutivo":

  - non movimenta né impegna la merce

  - non utilizza/impegna il protocollo (utilizza numerazioni negative)

  - non genera fattura né altro tipo di movimenti contabili

  - non genera scadenze

  - non può essere evaso (indipendentemente dello stato "Prelevabile")

EndText



Return DoDefault()

ENDPROC


*======================================================================

*** CLASS / OBJECT: chkPrelevabile (BaseClass: checkbox, Parent: fedi.PF.pgGenerale.PF.pgGenerale.cntStato) ***
*** PROPERTIES ***
Comment = "3960950D-1BED-4F6C-83FF-AAE8D3CF24CF"

Top = 53

Left = 2

Height = 16

Width = 70

Alignment = 0

Caption = "Prelevabile"

Value = .F.

ControlSource = "DOTES.Prelevabile"

TabIndex = 3

ToolTipText = "Impostare questo flag per rendere Prelevabile il documento; un documento NON Prelevabile non può essere evaso"

Name = "chkPrelevabile"


*** METHODS ***
PROCEDURE Init

Text To This.ToolTipText

Togliere la spunta per rendere "Non Prelevabile" il documento.

Un documento "Non Prelevabile" non potrà essere evaso.

EndText



Return DoDefault()

ENDPROC


*======================================================================

*** CLASS / OBJECT: chkModificabile (BaseClass: checkbox, Parent: fedi.PF.pgGenerale.PF.pgGenerale.cntStato) ***
*** PROPERTIES ***
Comment = "4B50804D-6DF4-4FD9-B195-FA451B2D21AB"

Top = 21

Left = 2

Height = 16

Width = 74

Alignment = 0

Caption = "Modificabile"

Value = .F.

ControlSource = "DOTES.Modificabile"

TabIndex = 4

ToolTipText = "Impostare questo flag per rendere Modificabile il documento; un documento NON Modificabile non può essere modificato ma può essere regolarmente evaso"

Name = "chkModificabile"


*** METHODS ***
PROCEDURE Init

Text To This.ToolTipText

Togliere la spunta per rendere "Non modificabile" il documento.

Un documento "Non modificabile":

  - non potrà essere modificato

  - non potrà essere eliminato

  - potrà essere evaso (se lo stato Esecutivo e Prelevabile lo permettono)

EndText



Return DoDefault()

ENDPROC


*======================================================================

*** CLASS / OBJECT: txtCd_LS (BaseClass: container, Parent: fedi.PF.pgGenerale.PF.pgGenerale) ***
*** PROPERTIES ***
Anchor = 8

Top = 208

Left = 377

Width = 265

Height = 80

TabIndex = 7

ZOrderSet = 7

Name = "txtCd_LS"

Label.Comment = "EDECC8A9-C61D-4486-A321-DA714DA25C80"

Label.Caption = "Listini"

Label.Left = 5

Label.Top = 3

Label.Visible = .F.

Label.TabIndex = 1

Label.Name = "Label"


*** METHODS ***
PROCEDURE Refresh

If InList(DOTes.Cd_LS_1, LS_UVEN_C, LS_UVEN, LS_UACQ_F, LS_UACQ)

	This.Field1  .Visible = .F.

	This.Display1.Visible = .F.

Else

	This.Field1  .Visible = .T.

	This.Display1.Visible = .T.

EndIf 

ENDPROC


*======================================================================

*** CLASS / OBJECT: Field2 (BaseClass: textbox, Parent: fedi.PF.pgGenerale.PF.pgGenerale.txtCd_LS) ***
*** PROPERTIES ***
ControlSource = "dotes.cd_ls_c"

Format = "!"

Left = 2

TabIndex = 7

ToolTipText = "Listino per i componenti"

Top = 61

Visible = .F.

Width = 55

fkselect = SELECT * FROM LS WHERE Cd_LS = <TEXT>

fktabledesc = Listini

fkdecodedfield = Descrizione

fkhasdisplay = .T.

Name = "Field2"


*** METHODS ***
PROCEDURE isvalid

LParameters lIsChanged, xOldValue



Local xRet

xRet = DoDefault(lIsChanged, xOldValue)

If Empty(xRet)

	Return xRet

EndIf



** Controllo se la valuta associata ha un fixing

If !IsEmpty(This.Value) And xSqlExec2Var(Textmerge('Select ExitCode From GetFixing(<<FormatC4Spt(This.FkRecord.Cd_VL)>>, <<FormatD4Spt(DoTes.DataDoc)>>)')) < 0

	xMessageBox(Thisform.TB_(,"1F25D44A-AFAC-4F1D-9DC9-F48B36118468", 'La valuta associata al listino %1! non ha alcun fixing. Non è possibile utilizzare tale listino.', This.Value), 48)

	This.FkShowDescription('')

	Return .F.

EndIf



ENDPROC

PROCEDURE fkshowdescription

Lparameters cDescText



With This 

	.ToolTipText = 'Listino per i Componenti' + Iif(IsEmpty(cDescText), '', ' - ' + Rtrim(cDescText))

	If .FKHasDisplay

		.Parent.Display2.Caption = cDescText

	EndIf

EndWith







ENDPROC

PROCEDURE visible_assign

LParameters lNewValue

This.Parent.Display2.Visible = lNewValue

This.Visible = lNewValue

ENDPROC


*======================================================================

*** CLASS / OBJECT: ChkIvaSospesa (BaseClass: checkbox, Parent: fedi.PF.pgGenerale.PF.pgGenerale.cntDatiContabili) ***
*** PROPERTIES ***
Comment = "2494463F-8961-4E9B-8FDC-B5C20B4C2C13"

Top = 21

Left = 403

Height = 16

Alignment = 0

Caption = "Iva esigibilità differita"

ControlSource = "Dotes.IvaSospesa"

TabIndex = 6

ToolTipText = "Documento con IVA ad esigibilità differita."

ZOrderSet = 18

Name = "ChkIvaSospesa"


*** METHODS ***
PROCEDURE onvaluechange

LPARAMETERS xOldValue



DoDefault(xOldValue)



If This.Value And Dotes.Clifor = 'F' And (Dotes.TipoFattura != 0 And Dotes.Tipofattura != RC_SPL)

	xMessageBox(Thisform.TB_(,'EFAAE788-E4B8-4AA5-81AD-A740FEB8EF34', "La gestione dell'iva per cassa non è prevista per acquisti UE ed in regime di inversione contabile."), MB_ICONEXCLAMATION)

EndIf



Thisform.SetRegimeIva('IVASOSPESA', xOldValue)





ENDPROC


*======================================================================

*** CLASS / OBJECT: chkIvaSplit (BaseClass: checkbox, Parent: fedi.PF.pgGenerale.PF.pgGenerale.cntDatiContabili) ***
*** PROPERTIES ***
Comment = "43E22C0F-BCF8-4526-A18B-16F1499DFFC3"

Top = 21

Left = 276

Alignment = 0

Caption = "Scissione pagamenti"

ControlSource = "Dotes.IvaSplit"

TabIndex = 5

ToolTipText = "Documento con scissione dei pagamenti, articolo 17-ter"

ZOrderSet = 18

Name = "chkIvaSplit"


*** METHODS ***
PROCEDURE onvaluechange

LPARAMETERS xOldValue



DoDefault(xOldValue)



Thisform.SetRegimeIva('IVASPLIT', xOldValue)





ENDPROC


*======================================================================

*** CLASS / OBJECT: cntAttributi (BaseClass: container, Parent: fedi.PF.pgGenerale.PF.pgInfo) ***
*** PROPERTIES ***
Anchor = 7

Top = 188

Left = 2

Width = 320

Height = 170

TabIndex = 9

ZOrderSet = 3

tablerif = DOTES

Name = "cntAttributi"

border.Top = 20

border.Left = 0

border.Height = 73

border.Width = 200

border.Name = "border"

LV.Top = 20

LV.Left = 0

LV.Height = 73

LV.Width = 200

LV.Name = "LV"

title_label.FontSize = 10

title_label.Height = 19

title_label.Left = 0

title_label.Top = 0

title_label.Width = 320

title_label.Name = "title_label"

lblAssegna.Left = 71

lblAssegna.Top = 1

lblAssegna.Name = "lblAssegna"


*** METHODS ***
PROCEDURE Init

DoDefault()



ObjMov(This.Lv, 			 1, 21, This.Width-2, This.Height - 22)

ObjMov(This.Border, This.Lv.Left-1, This.Lv.Top-1, This.Lv.Width+2, This.Lv.Height+2)

ENDPROC


*======================================================================

*** CLASS / OBJECT: txtCambio (BaseClass: container, Parent: fedi.PF.pgGenerale) ***
*** PROPERTIES ***
Top = 4

Left = 337

Width = 78

Height = 30

TabIndex = 8

TabStop = .F.

ZOrderSet = 5

Name = "txtCambio"

Label.Comment = "C14CA674-EC1E-491D-BBB6-8C1F833B6AC2"

Label.Anchor = 9

Label.Caption = "Cambio"

Label.Left = 43

Label.Top = -2

Label.ZOrderSet = 0

Label.Name = "Label"


*** METHODS ***
PROCEDURE zoom_recursive

DoDefault()



** Mi assicuro che l'allineamento a dx della label sia corretto

ObjMov(This.Label, This.Field.Width - TextWidthObj(This.Label.Caption, This.Label))



ENDPROC


*======================================================================

*** CLASS / OBJECT: txtCFDest (BaseClass: container, Parent: fedi.PF.pgGenerale) ***
*** PROPERTIES ***
Top = 4

Left = 92

Width = 35

Height = 30

TabIndex = 3

ZOrderSet = 6

Name = "txtCFDest"

Label.AutoSize = .F.

Label.Comment = "6F91A80C-9D4A-4CDF-9B14-E1D845F66399"

Label.BackStyle = 1

Label.Caption = "S.O."

Label.Height = 16

Label.Left = 1

Label.Top = -2

Label.Width = 34

Label.BackColor = 0,255,255

Label.Name = "Label"


*** METHODS ***
PROCEDURE Init

DoDefault()

This.Label.BackStyle = 1

ENDPROC

PROCEDURE Label.Init

DoDefault()



This.BackColor = RgbLighter(oApp.MainColor, 0.9)

ENDPROC


*======================================================================

*** CLASS / OBJECT: txtCFSede (BaseClass: container, Parent: fedi.PF.pgGenerale) ***
*** PROPERTIES ***
Top = 4

Left = 128

Width = 35

Height = 30

TabIndex = 4

ZOrderSet = 8

Name = "txtCFSede"

Label.AutoSize = .F.

Label.Comment = "5B18B41D-EDF3-4672-8794-130B6EE3072F"

Label.BackStyle = 1

Label.Caption = "S.A."

Label.Height = 16

Label.Left = 1

Label.Top = -2

Label.Width = 34

Label.BackColor = 0,255,255

Label.Name = "Label"


*** METHODS ***
PROCEDURE Init

DoDefault()

This.Label.BackStyle = 1

ENDPROC

PROCEDURE Label.Init

DoDefault()



This.BackColor = RgbLighter(oApp.MainColor, 0.9)

ENDPROC


*======================================================================

*** CLASS / OBJECT: cntTesta2 (BaseClass: container, Parent: fedi.PF.pgGenerale) ***
*** PROPERTIES ***
Anchor = 10

Top = 0

Left = 419

Width = 227

Height = 60

TabIndex = 9

TabStop = .F.

ZOrderSet = 9

Name = "cntTesta2"


*** METHODS ***
PROCEDURE Refresh

Lparameters lRefreshLblLabel



DoDefault(lRefreshLblLabel)



** N.B.: Il refresh del Cli/For DEVE avvenire PRIMA del refresh della DestDiv

**			ed entrambi PRIMA del refresh del container con l'indirizzo



Local oFldCF			&&	This.parent.txtCd_CF.Field

Local oFldCFDest		&&	This.parent.txtCFDest.Field

Local oFldCFSede		&&	This.parent.txtCFSede.Field

Local oFldDO			&& This.Parent.txtCd_DO.Field

 

Local oRec				&& .FKRecord   di This.parent.txtCd_CF.Field o This.parent.txtCFDest.Field

Local oRecCF			&&	.FKRecord   di This.parent.txtCd_CF.Field

Local oRecCFDest		&&	.FKRecord   di This.parent.txtCFDest.Field

Local oRecCFSede		&&	.FKRecord   di This.parent.txtCFSede.Field



** oFldCF		= This.Parent.txtCd_CF.Field

oFldCF		= Iif(This.Parent.txtCd_CF.Visible, This.Parent.txtCd_CF.Field, This.Parent.txtCd_CF_Auto.Field)



** -----------------------------



If lRefreshLblLabel



	This.lblAlert.Caption = Iif(oFldCF.FkRecord.EntePubblico, TB_(, "DBA16B86-EAC5-49A5-A0BD-79E1550A78E7", " !! Cliente privo di Codice Ufficio !! "),	;

																	 			 TB_(, "5C397C54-9CBD-4017-BBFA-59E5C351200F", " !! Cliente privo di Codice Destinatario / PEC B2B !! "))

																 	 

	This.lblAlert.Visible = Thisform.Mode = FEDIMODE_INS And ;

									oApp.LicInfo.FatturaElettronica And ;

									InList(Left(oFldCF.FkRecord.Cd_CF, 1), 'C', 'P') And ;

									((oFldCF.FkRecord.EntePubblico And IsEmpty(oFldCF.FkRecord.CodiceIPA)) Or (!oFldCF.FkRecord.EntePubblico And IsEmpty(oFldCF.FkRecord.CodiceFPR)))



	ObjMov(This.lblAlert, This.ddrow3.Left, This.ddrow3.Top)



	Return 

EndIf 



** -----------------------------



oFldCFDest	= This.Parent.txtCFDest.Field

oFldCFSede	= This.Parent.txtCFSede.Field

oFldDO		= This.Parent.txtCd_DO.Field



** Ottimizzazione

If This.LastCd_CF == Nvl(oFldCF.Value, '') And This.LastCFDest == Nvl(oFldCFDest.Value, '') And This.LastTipoDocumento == Nvl(oFldDO.FkRecord.TipoDocumento, '')

	Return

EndIf



This.LastCd_CF   			= Nvl(oFldCF.Value,     '')

This.LastCFDest  			= Nvl(oFldCFDest.Value, '')

This.LastTipoDocumento 	= Nvl(oFldDO.FkRecord.TipoDocumento, '')



oRecCF = oFldCF.FKRecord



oFldCFDest.FKSelect = Textmerge("Select * From CFDest Where CFDest.Cd_CF = '<<oRecCF.Cd_CF>>' And CFDest.Cd_CFDest = <TEXT>")

oFldCFSede.FKSelect = Textmerge("Select * From CFSede Where CFSede.Cd_CF = '<<oRecCF.Cd_CF>>' And CFSede.Cd_CFSede = <TEXT>")



oFldCFDest.OnRefresh()

oFldCFSede.OnRefresh()



oRecCFDest	= oFldCFDest.FKRecord

oRecCFSede	= oFldCFSede.FKRecord	



This.DDRow1.Caption = 	oRecCF.Descrizione

This.DDRow2.Caption = 	Rtrim(Nvl(oRecCF.Indirizzo, '')) + ' - ' + ;

								Rtrim(Nvl(oRecCF.Cap,       '')) + ' '   + ;

								Rtrim(Nvl(oRecCF.Localita,  '')) + ;

								Iif(IsEmpty(oRecCF.Cd_Provincia), '', ' (' + oRecCF.Cd_Provincia + ')')



This.DDRow3.Caption = ''

If InList(Left(oRecCF.Cd_CF, 1), 'C', 'P')  

	This.DDRow3.Caption = ICase(!IsEmpty(oRecCF.CodiceFPR), 	Iif(Len(Rtrim(oRecCF.CodiceFPR)) = 7, 	'Codice Destinatario: ' + Rtrim(oRecCF.CodiceFPR), 'Email PEC: ' + Rtrim(oRecCF.CodiceFPR)), ;

										 !IsEmpty(oRecCF.CodiceIPA), 													  	'Codice IPA: ' + Rtrim(oRecCF.CodiceIPA), ;

																		 	  														'')

EndIf 





** Destinazione diversa

This.SORow.Caption = ''

If !IsEmpty(oFldCFDest.Value)

	This.SORow.Caption = Iif(Rtrim(Upper(oRecCF.Descrizione))!=Rtrim(Upper(oRecCFDest.Descrizione)), 	Rtrim(    oRecCFDest.Descrizione)    + ' - ', '') + ;

																																		Rtrim(Nvl(oRecCFDest.Indirizzo, '')) + ' - ' + ;

																																		Rtrim(Nvl(oRecCFDest.Cap,       '')) + ' '   + ;

																																		Rtrim(Nvl(oRecCFDest.Localita,  '')) + ;

																																	 	Iif(IsEmpty(oRecCFDest.Cd_Provincia), '', ' (' + oRecCFDest.Cd_Provincia + ')')																															 	

	If Thisform.Fte_Isxml()																																	 	

			This.SORow.Caption = This.SORow.Caption + Iif(!IsEmpty(oRecCFDest.CodiceIPA), ' - Cod. Uff. ' + oRecCFDest.CodiceIPA, ;

																	Iif(!IsEmpty(oRecCFDest.CodiceFPR), ' - ' + Iif(Len(Rtrim(oRecCFDest.CodiceFPR)) = 7, 'Cod.Dest.: ', 'Email PEC: ') + Rtrim(oRecCFDest.CodiceFPR), ''))

	EndIf 

EndIf 



If !IsEmpty(This.DDRow3.Caption) Or Thisform.Mode = FEDIMODE_INS		&& se sono in inserimento, lascio lo spazio per la lblAlert

	*bjMov(This.SORow,, This.DDRow3.Top + 14)

	ObjMov(This.SORow,, This.DDRow3.Top + (This.DDRow3.Top-This.DDRow2.Top))	&& per ArcaZoom non bisogna usare più posizione fisse, ma sempre relative...

Else

	ObjMov(This.SORow,, This.DDRow3.Top)

EndIf 

ENDPROC

PROCEDURE Init



THIS.AddProperty('LastCd_CF',  'XX')

THIS.AddProperty('LastCFDest', 'YY')

THIS.AddProperty('LastTipoDocumento', 'Z')



DODEFAULT()



ENDPROC


*======================================================================

*** CLASS / OBJECT: SORow (BaseClass: label, Parent: fedi.PF.pgGenerale.cntTesta2) ***
*** PROPERTIES ***
AutoSize = .T.

Comment = "01745B9B-D53A-4182-BD63-872F6958F583"

BackStyle = 0

Caption = "xxxxxxxxxxxxxxxxxxxxxxxxxx"

Left = 3

Top = 45

ForeColor = 0,0,128

Name = "SORow"


*** METHODS ***
PROCEDURE Init

DoDefault()



This.ForeColor = Rgb(0,0,128)

ENDPROC


*======================================================================

*** CLASS / OBJECT: lblAlert (BaseClass: label, Parent: fedi.PF.pgGenerale.cntTesta2) ***
*** PROPERTIES ***
AutoSize = .T.

BackStyle = 1

Caption = " !! Cliente privo di Codice Destinatario !!  "

Left = 180

Top = 30

Visible = .F.

ForeColor = 255,255,255

BackColor = 229,32,46

Name = "lblAlert"


*** METHODS ***
PROCEDURE Init

DoDefault()



This.BackColor = RgbLighter(oApp.MainColor, 0.2)

ENDPROC


*======================================================================

