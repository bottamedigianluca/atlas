*** Extracted Visual FoxPro Source Code from Cmd_DoPrelievoCreazione.vcx ***

*** CLASS / OBJECT: cmd (BaseClass: form, Parent: ) ***
*** PROPERTIES ***
Top = 1

Left = 1

Height = 503

Width = 684

DoCreate = .T.

Comment = "51BE291D-6A4D-459D-B7D2-789B1364E218"

Caption = "Evasione - Creazione Documenti Guidata"

WindowState = 0

mode = ''

dobitmask = (0x7FFFFFFF)

Name = "cmd"

StatusBar.BorderLine.Name = "BorderLine"

StatusBar.TimerDate.Name = "TimerDate"

StatusBar.TimerRepos.Name = "TimerRepos"

StatusBar.Comment = "3C269045-06FF-43CD-B797-399F64421A95"

StatusBar.Top = 483

StatusBar.Left = 0

StatusBar.Width = 684

StatusBar.Height = 20

StatusBar.TabIndex = 2

StatusBar.Name = "StatusBar"

title_bar.BtnLabel.Name = "BtnLabel"

title_bar.lblLabel.Name = "lblLabel"

title_bar.Comment = "E5C52F86-149A-4646-8894-543DBFD6B877"

title_bar.Top = 26

title_bar.Width = 684

title_bar.TabIndex = 4

title_bar.Name = "title_bar"

timer4ExecAsync.Comment = "193F98C6-0FE6-45FE-B09B-B9B95CC1D711"

timer4ExecAsync.Name = "timer4ExecAsync"

SCMenu.Comment = "70B6A9EA-5F71-4795-B504-355C923D70F3"

SCMenu.Name = "SCMenu"

tbenabler.Comment = "4AD77A9E-CBD5-48D8-927F-3CDBD31DEC1E"

tbenabler.Name = "tbenabler"

PF.ErasePage = .T.

PF.PageCount = 8

PF.Pgbase1.Comment = "05632E8C-3142-4592-84D5-02BBCF549C0F"

PF.Pgbase1.Caption = "Modalità di Creazione"

PF.Pgbase1.PageOrder = 1

PF.Pgbase1.Name = "pgGenerale"

PF.Pgbase2.Comment = "1270D012-93CC-4C0E-812B-1A62E5D77180"

PF.Pgbase2.Caption = "Documento da Creare"

PF.Pgbase2.PageOrder = 2

PF.Pgbase2.Name = "pgDocumento"

PF.Pgbase3.Comment = "D8082A2F-DC9E-4022-8F99-4C2F89A43FFA"

PF.Pgbase3.Caption = "Selezione Documenti"

PF.Pgbase3.PageOrder = 3

PF.Pgbase3.Name = "pgSelTeste"

PF.Pgbase4.Comment = "64CF9756-6C49-4886-B0C5-36EF12585655"

PF.Pgbase4.Caption = "Teste"

PF.Pgbase4.PageOrder = 4

PF.Pgbase4.Name = "pgTeste"

PF.Pgbase5.Comment = "82E62DFA-AB72-42C9-A20E-4C2076CF040F"

PF.Pgbase5.Caption = "Selezione Righe"

PF.Pgbase5.PageOrder = 5

PF.Pgbase5.Name = "pgSelRighe"

PF.Pgbase6.Comment = "D08A6852-D6B2-4155-917E-2B470540B3CD"

PF.Pgbase6.Caption = "Righe"

PF.Pgbase6.PageOrder = 7

PF.Pgbase6.Name = "pgRighe"

PF.Pgbase7.Comment = "EB615026-169E-4227-8BF9-DC1BA2C8F43A"

PF.Pgbase7.Caption = "Inserimento Righe"

PF.Pgbase7.PageOrder = 8

PF.Pgbase7.Name = "pgInsRighe"

PF.Pgbase8.Caption = "Selezione Avanzata Righe per Quantità"

PF.Pgbase8.PageOrder = 6

PF.Pgbase8.Name = "pgSelRigheAvanzata"

PF.Comment = "EBE07CC8-6DCB-41CF-98ED-CA6E6E573DA3"

PF.ActivePage = 1

PF.Top = 28

PF.Width = 686

PF.Height = 454

PF.TabIndex = 1

PF.Name = "PF"


*** METHODS ***
PROCEDURE checkallrifexp

Local xExp, lRet



cBadExp = ''

oWA = SELECTWA('DODOPREL')





Scan

	If GeneraRif

		lRet = DoEvalRigaRif(RifExp, 'DOTES', @xExp)

		If !lRet

			cBadExp = cBadExp + Cd_DO_Prelevabile + ' ' + Descrizione + CRLF

		EndIf

	EndIf

EndScan



If !Empty(cBadExp)

	xMessageBox(Thisform.TB_(,'6E128A1B-09B6-4E11-9E3E-8B0462748606', 'Le espressioni di riferimento per:' + CRLF + '%1' + 'Risultano non corrette, quindi non genereranno la riga di riferimento in fase di prelievo.', cBadExp))

EndIf



ENDPROC

PROCEDURE getwheredotes

Local cWhere



cWhere = This.PF.WCGetWherePage(This.PF.pgSelTeste) + ;

			' And Esecutivo = 1 ' + ;

			Iif(InList(Thisform.Mode, 'EVADI', 'EVADISINGLE')  , 'And DOTes.Prelevabile = 1 And DOTes.RigheEvadibili > 0 ', '') + ;

			Iif(!Empty(This.WCDocFilter), 'And DOTes.Cd_DO In (' + This.WCDocFilter + ') ', '')



Return cWhere





ENDPROC

PROCEDURE getdocprelist

Local nTotal, i, cRet



cRet = ''

With ThisForm.PF.pgDocumento.lstDoc

	nTotal = .ListCount

	i = 1

	For  i = 1 To nTotal

		If .SelectedChkID(i)

			cRet = cRet + ',' + Format4Spt(.List(i,1))

		EndIf

	EndFor

	cRet = SubStr(cRet, 2)

EndWith

Return cRet



ENDPROC

PROCEDURE requerydorig

Local cWhereDoRig, cWhereDoSpe, cOrderByRig, cId_DoTesList

Local lSelezioneAvanzataRighe , lSoloArticoliInLista, lQuantitaFissa

Local oCtrl



Local nResiduo, nQtaEvadibileDoRig



cWhereDoRig = ''

cWhereDoSpe = ''

cOrderByRig = ''



If This.PF.pgDocumento.chkSelezioneAvanzataRighe.Value And This.PF.pgSelRigheAvanzata.Enabled = .T.

	lSelezioneAvanzataRighe = .T.

	lSoloArticoliInLista		= This.PF.pgSelRigheAvanzata.cntPrelievoQta.chkSoloArticoliPerQuantita.Value

	lQuantitaFissa				= This.PF.pgSelRigheAvanzata.cntPrelievoQta.chkQuantitaFissa			 .Value				

EndIf



** cWhereDoRig 

If This.PF.pgDocumento.chkSelezioneAvanzataRighe.Value And This.PF.pgSelRighe.Enabled = .T.

	If lSoloArticoliInLista

		** "Sotto" mi servono tutti gli articoli anche se poi gestisco solo quelli della lista

		cWhereDoRig = ''

	Else

		cWhereDoRig = This.PF.pgSelRighe.cnt.wcGetWhere()

	EndIf 

EndIf



** cWhereDoSpe

cWhereDoSpe = This.PF.pgSelRighe.cmbTipoSpesa.wcGetWhere()



** cOrderByRig

If lSelezioneAvanzataRighe

	oCtrl = This.PF.pgSelRigheAvanzata.cntPrelievoQta.cmbOrdinePrelievoARQta

	If !IsEmpty(oCtrl.ListItem(oCtrl.ListIndex, 2))

		cOrderByRig = oCtrl.ListItem(oCtrl.ListIndex, 2)

		oCtrl       = This.PF.pgSelRigheAvanzata.cntPrelievoQta.cmbVersoOrdinePrelievoARQta

		cOrderByRig = cOrderByRig + ' ' + oCtrl.ListItem(oCtrl.ListIndex, 2)			

	EndIf

Else

	cOrderByRig = ''

EndIf



** Modifico cWhereDoRig e cWhereDoSpe in base alla lista di Id_DoTes ricavata dalle teste selezionate

cId_DoTesList = ''

Select DoTes

Scan For Selected 

	cId_DoTesList = cId_DoTesList + ',' + Tran(Id_DoTes)

EndScan

cId_DoTesList = SubStr(cId_DoTesList, 2)

If Empty(cId_DoTesList)

	cWhereDoRig = cWhereDoRig + ' And 1=0'

	cWhereDoSpe = cWhereDoSpe + ' And 1=0'

Else

	cWhereDoRig = cWhereDoRig + ' And DoRig.Id_DoTes In (' + cId_DoTesList + ')'

	If !ThisForm.PF.pgDocumento.chkPrelevaRigheRif.Value

		 cWhereDoRig = cWhereDoRig + " And TipoRigaRif = ''"

	EndIf

	cWhereDoSpe = cWhereDoSpe + ' And DORigSpesa.Id_DoTes In (Select Id_DoTes From DoRig Where ' + Substr(cWhereDoRig, 5) + ')'

EndIf



With ThisForm.PF.pgRighe

	.Grid.SaveRecordSource()

	.GridRigheSpesa.SaveRecordSource()



	TableRevert(.T., 'DORig')

	Thisform.PF.pgInsRighe.Grid.SaveRecordSource()

	This.QueryDoRig(cWhereDoRig, cOrderByRig)



	** Preparo DoRig

	Replace Selected With .F. All In DoRig



	** Se è stata compilata la griglia di prelievo allora ne tengo conto nella logica

	** prelevando/filtrando in base a quanto indicato manualmente, altrimenti no

	If lSoloArticoliInLista



		** Dalle righe inserite a mano estraggo un cursore compattato ai fini del prelievo/filtro

		TableUpdate(.T., .F., 'ARQta')



		Select																					;

			ARQta.Cd_AR							As Cd_AR,									;

			ARQta.Cd_ARMisura					As Cd_ARMisura,							;

			ARQta.UMFatt						As UMFatt,									;

			ARQta.Descrizione					As Descrizione,							;

			Sum(ARQta.Qta * ARQta.UMFatt) As Qta										;

		From																						;

			ARQta																					;

		Where																						;

			!IsEmpty(ARQta.Cd_AR)															;

		Group By																					;

			ARQta.Cd_AR, ARQta.Cd_ARMisura, ARQta.UMFatt, ARQta.Descrizione	;

		Into																						;

			Cursor ARQtaWrk Nofilter

			

		Select ARQtaWrk

		Scan

			nResiduo = ARQtaWrk.Qta		&&--> Quantita in unità di misura principale

				

			Select DoRig

			Scan For nResiduo > 0 And (DoRig.Cd_AR == ARQtaWrk.Cd_AR) And (DoRig.QtaResidua > 0)

				

				** Controllo che la riga sia in evasione e selezionata

				Seek DoRig.Id_DoTes Order Tag Id_DoTes In DoTes

				If Found('DoTes') And DoTes.Selected



	**				Replace Selected With .T.,	FattoreToUM1_RE With 1 In DoRig				

					Replace Selected With .T. In DoRig



					** Calcolo la quantità evadibile residua della riga (si abbassa durante il ciclo) e procedo

					nQtaEvadibileDoRig = DoRig.QtaResidua * DoRig.FattoreToUM1

					If nResiduo > nQtaEvadibileDoRig	&&--> deve essere prelevata l'intera riga per l'intera quantità

						Replace Qta With DoRig.QtaEvadibile In DoRig

						nResiduo = nResiduo - nQtaEvadibileDoRig

					Else										&&--> prelevo la riga per la quantità rimanente

						Replace Qta With DoRig.Qta + nResiduo / FattoreToUM1 In DoRig

						nResiduo = 0

					EndIf



					This.OnRowQtaChange()				&&--> aggiorna anche DoRig.QtaResidua per il ciclo successivo



				Else

					** La riga o è in evasione ma non è selezionata (non dovrebbe mai succedere ma se è così la cancello)

					** oppure non è in evasione ma è una delle righe aggiunte per quadrare la quantità fissa (la tengo)

					If DoRig.Id_DoTes != -1

						Delete In DORig

					EndIf

				EndIf

				

			EndScan	&&--> DoRig

			

			If nResiduo > 0 And lQuantitaFissa	&&--> devo aggiungere righe supplementari per ottenere la quantità fissa

				

				Local oRecTes, oRecRig

				**oRecTes = This.oParmPrel.oRecTes

				**Scatter Name oRecTes Memo

				

				oRecTes = CreateObject('Empty')

				AddProperty(oRecTes, 'Cd_DO', 	This.Pf.pgDocumento.cmbCd_DO					.Value )

				AddProperty(oRecTes, 'Cd_CF', 	This.Pf.pgDocumento.txtCd_CF			.Field.Value )

				AddProperty(oRecTes, 'DataDoc', 	This.Pf.pgDocumento.txtDataDocumento.Field.Value )

				*AddProperty(oRecTes, 'Cambio',	This.Pf.pgDocumento.txtCd_VL.Field.FkRecord.Cambio)

				

				xSqlExec("Select * From DoRig Where 1=0", "_Res")

				Select _Res

				Append Blank 

				oRecRig = DoRig_Defaults_2Obj_Ex(.T., oRecTes.Cd_DO, oRecTes.Cd_CF, oRecTes.DataDoc,,,,,,,,, 1, ARQtaWrk.Cd_AR, nResiduo / ARQtaWrk.UMFatt, ARQtaWrk.Cd_ARMisura, ARQtaWrk.UMFatt)

				Gather  Memo Name oRecRig

				Scatter Memo Name oRecRig

				Use In _Res

				AddProperty(oRecRig, 'QtaEvadibile'		, oRecRig.Qta			 )												

				AddProperty(oRecRig, 'Selected'			, .T.						 )

				AddProperty(oRecRig, 'FattoreToUM1_RE'	, 1						 )

				AddProperty(oRecRig, 'Descrizione'		, ARQtaWrk.Descrizione)	

				AddProperty(oRecRig, 'Id_DoTes'			, -1						 )	

				DoRig_Formulae(oRecRig)

				

				Select DoRig

				Append Blank

				Gather Memo Name oRecRig 

				

			EndIf

					

		EndScan

		Use In ARQtaWrk	

	

	EndIf 



	If lSoloArticoliInLista	

		Delete For !DoRig.Selected And DoRig.TipoRigaRif = ' ' In DoRig

	Else

		Select DoRig

		Scan For !Selected

			If InList(This.Mode, 'EVADI', 'EVADISINGLE')

				Replace Selected With .T., Qta With DoRig.QtaEvadibile, QtaResidua With 0 In DoRig

			Else

				** Copia

				Replace Selected With .T. In DoRig

			EndIf 

		EndScan	

	EndIf

	

	Thisform.PF.pgInsRighe.Grid.RestoreRecordSource()



	** Normalizzo i codici magazzino

	Select DORig

	Scan

		Scatter Name oRigaDoc Memo

		ThisForm.NormMagazzini(oRigaDoc)

		Gather Name oRigaDoc Memo

	EndScan



	Go Top



	TableRevert(.T., 'DORigSpesa')

	Go Top

	This.QueryDoRigSpesa(cWhereDoSpe)



	.GridRigheSpesa.RestoRerecordSource()

	.Grid.RestoRerecordSource()



	*ThisForm.cmdRowUnSel(1)

	*ThisForm.cmdRowSel(1)



EndWith





ENDPROC

PROCEDURE querydorig

LParameters cWhere, cOrderBy



** Cd_ARMisura e FattoretoUM1 sono i valori corretti dal punto di vista della riga quando sarà messa nel documento.

**	Cd_ARMisura_RE e FattoretoUM1_RE sono invece da usarsi solo nella griglia di prelivo

**	e fanno riferimento all'unità di misura e relativo fattore di conversione della riga come era nel documento prelevato.

**

** QtaResidua  QtaResidua sul documento non sarà visibile: è di quanto lascio aperto la riga prelevata

**					e si calcola come QtaEvadibile - (Qta * FattoreToUM1 / FattoreToUM1_RE) gestendo l'eccezione che

**					il residuo NON PUO' essere negativo.

**

**	Finita la fase di input da parte dell'utente, ho in Qta quando vuole prelevare ed in QtaResidua quanto si

**	vuole lasciare aperto nella riga prelevata.

**

** A questo punto prima di passare la riga alla form documenti:

**

** 1) Inizializzo Id_DoRig_Evade = Id_DoRig

**	2) Inizializzo Id_DoRig			= 0	(la riga è una riga in inserimento, nuova)

**	3) Inizializzo QtaEvasa       = QtaEvadibile - QtaResidua

**	4) Inizializzo QtaEvadibile   = Qta

**	5) Inizializzo PrezzoTotaleV 	= Qta * PrezzoUnitarioScontatoV



Local cQuery



TEXT TO cQuery TEXTMERGE NOSHOW



	SELECT

		CONVERT(BIT, 1) 					AS Selected,

		<<ColumnsList('DORig')>>,



		0										AS QtaEvasa_InOrigine,

		

		DORig.Cd_AR							AS DocEvaso_Cd_AR, 

		ARCodCF.CodiceAlternativo 		AS DocEvaso_CodiceAlternativo, 

		DORig.FattoreToUm1 				AS DocEvaso_FattoreToUM1,

		DORig.Riga							AS DocEvaso_Riga,

		DORig.Cd_DO							AS DocEvaso_Cd_DO,

		DORig.NumeroDoc					AS DocEvaso_NumeroDoc,

		DORig.Qta							AS DocEvaso_Qta,

		ISNULL(DORig.QtaEvadibile, 0) AS DocEvaso_QtaEvadibile,

		DORig.Cd_ARMisura					AS DocEvaso_Cd_ArMisura,

		DORig.DataDoc 						AS DocEvaso_DataDoc,



		DORig.QtaEvadibile 				AS QtaResidua,

		DORig.Cd_ARMisura					AS Cd_ARMisura_RE,

		DORig.FattoretoUM1 				AS FattoretoUM1_RE,



		(CASE DORig.FattoretoUM1

			WHEN 0 THEN 0

			ELSE DORig.PrezzoUnitarioV / DORig.FattoretoUM1 END ) AS PrezzoUnitarioV_UM

		

		FROM

			DORig

			Left Join ARCodCF On ARCodCF.Cd_CF = DORig.Cd_CF And ARCodCF.Cd_AR = DORig.Cd_AR 

	WHERE << IIF(InList(THISFORM.Mode, 'EVADI', 'EVADISINGLE'), "((Evadibile = 1 AND QtaEvadibile != 0) OR TipoRigaRif != ' ')", "1=1 ") >> << cWhere >>

	ORDER BY << Evl(cOrderBy, Iif(Type('This.PF.pgteste.cmbOrderBy') = 'O', This.PF.pgTeste.cmbOrderBy.ListItem(This.PF.pgTeste.cmbOrderBy.ListIndex, 3), '1')) >>



EndText 





If xSqlExec(cQuery, 'DORig')= -1

	Return .F.

EndIf



Select DoRig

Scan

	cCd_ARMisura	= Cd_ARMisura

	nFattoretoUM1	= FattoretoUM1



	Replace 	Qta					With Iif(InList(This.Mode, 'EVADI', 'EVADISINGLE'), 0, 				Qta)			;

				QtaEvasa	 			With Iif(InList(This.Mode, 'EVADI', 'EVADISINGLE'), QtaResidua,	QtaEvasa)	;

				Cd_ARMisura 		With Cd_ARMisura_RE																				;

				Cd_ARMisura_RE		With cCd_ARMisura																					;

				FattoretoUM1 		With FattoretoUM1_RE																				;

				FattoretoUM1_RE	With nFattoretoUM1 																				;

				PrezzoTotaleV		With Iif(InList(This.Mode, 'EVADI', 'EVADISINGLE'), DoRig_PrezzoTotaleV(QtaEvasa, PrezzoUnitarioV, FattoreScontoTotale, PrezzoAddizionaleV, Decimali, 1), PrezzoTotaleV)	;

				QtaResidua	 		With Iif(InList(This.Mode, 'EVADI', 'EVADISINGLE'), QtaResidua, 0)				;

				NoteRiga 			With IIF(ISNULL(NoteRiga),'',NoteRiga) 													;

			In DoRig



EndScan



Return .T.





ENDPROC

PROCEDURE querydorigspesa

LPARAMETERS cWhere



**	Finita la fase di input da parte dell'utente, ho in ImportoV quanto vuole prelevare ed in ImportoResiduoV quanto si

**	vuole lasciare aperto nella riga prelevata.

**

** A questo punto prima di passare la riga alla form documenti:

**

** 1) Inizializzo Id_DoRigSpesa_Evade = Id_DoRig

**	2) Inizializzo Id_DoRigSpesa	= 0	(la riga è una riga in inserimento, nuova)

**	3) Inizializzo ImportoEvasoV  = ImportoEvadibileV - ImportoResiduoV

**	4) Inizializzo ImportoEvadibileV   = ImportoV



LOCAL cQuery



Text To cQuery TextMerge NoShow

	SELECT

		Convert(BIT, 1) AS Selected,

		<<ColumnsList('DORigSpesa')>>,

		DORigSpesa.ImportoV AS ImportoV_Originale,

		DOTes.Cd_CF,

		DOTes.Cd_DO,

		DOTes.NumeroDoc,

		DoRigSpesa.ImportoEvasoV * 0 		AS ImportoResiduoV,

		/* I CAMPI CHE MI SERVONO PER IL CALCOLO DELL'EVASO NEI WIZARD */

		DORigSpesa.ImportoEvasoV 			AS ImportoEvasoV_InOrigine,

		DORigSpesa.ImportoEvadibileV 		AS DocEvaso_ImportoEvadibileV,

		DORigSpesa.ImportoV 					AS DocEvaso_ImportoV			

	FROM

		DORigSpesa

	INNER JOIN DOTes ON DOTes.Id_DOTes = DORigSpesa.ID_DOTes

	WHERE <<IIF(InList(THISFORM.Mode, 'EVADI', 'EVADISINGLE'), ' ISNULL(ImportoEvadibileV, 0) != 0 ', ' 1=1 ')>>  <<cWhere>>

EndText



IF xSqlExec(cQuery, 'DoRigSpesa') = -1

	RETURN .F.

ENDIF



REPLACE ALL	 DORigSpesa.ImportoV			WITH DORigSpesa.ImportoEvadibileV IN DORigSpesa

Go Top 



RETURN .T.





ENDPROC

PROCEDURE requerydotes

Local cWhere

Local lSoloArticoliperQuantita



cWhere = Thisform.GetWhereDOTes()



With Thisform.PF.pgTeste

	.Grid.SaveRecordSource()

	Tablerevert(.T., 'DOTes')



	**THISFORM.DE.DOTes.Requery(cWhere)

	This.QueryDOTes(cWhere)



	Select DOTes

	Index On ID_DOTes Tag ID_DOTes Collate "Machine"

	Set Order To

	Go Top

	.Grid.RestoreRecordSource()

Endwith



ENDPROC

PROCEDURE querydotes

LParameters cWhere



Local cStmt



Text To cStmt Textmerge NoShow



	Select

		<<ColumnsList('DOTes',, 'Attributi,ExtraInfo,FTE_Status,Ud_FTE')>>,

		Convert(Bit, 1)	As Selected

	From DOTes

	Inner Join CF On CF.Cd_CF = DOTes.Cd_CF

	Where 1 = 1

		<< cWhere >>

	Order by DataDoc, Cd_DO, NumeroDoc

		

EndText



Return (xSqlExec(cStmt, 'DoTes') != -1)



ENDPROC

PROCEDURE querydodoprel

LParameters cWhere



Local cStmt

cWhere = SubStr(cWhere, 6)

Text To cStmt TextMerge Noshow



	Select

		Convert(Bit, 1)						As Selected,

	

		DoEvaso.Cd_DO							As Cd_DO_Prelevabile,

		DoEvaso.Descrizione					As Descrizione,

		DoEvaso.UIRigaRifExp					As RifExp,

		DoEvaso.UIRigaRifGenera				As GeneraRif,

		DoEvaso.UIRigaRifPreleva			As PrelevaRif



--		MGCausaleEvaso.MagPFlag				As MagPFlag,

--		MGCausaleEvaso.Cd_MG_P				As Cd_MG_P,

--		MGCausaleEvaso.MagAFlag				As MagAFlag,

--		MGCausaleEvaso.Cd_MG_A				As Cd_MG_A

			

	From DODOPrel

	Inner Join      DO DoEvaso						On					  DoEvaso.Cd_DO = DODOPrel.Cd_DO_Prelevabile

	Left Outer Join MGCausale MGCausaleEvaso	On MGCausaleEvaso.Cd_MGCausale = DoEvaso.Cd_MGCausale

		 

	Where << cWhere >>

	Order By DODOPrel.Cd_DO



EndText

Return (xSqlExec(cStmt, 'DoDoPrel') != -1)



ENDPROC

PROCEDURE onrowqtachange

Lparameters lFromQta



** accrocchio per riuscire a gestire la funzionalità solo quando serve



** ----- LICADAPTER

If lFromQta And oApp.LicInfo.MG_Main

	Thisform.ControlloGiacenza()

EndIf 



***************************************



LOCAL nNewQtaResidua, nDec



nNewQtaResidua = DoRig.QtaEvadibile - (DoRig.Qta * DoRig.FattoreToUM1 / DoRig.FattoreToUM1_RE)

nNewQtaResidua = IIF(DoRig.QtaEvadibile >= 0, MAX(0, nNewQtaResidua), MIN(0, nNewQtaResidua))



nDec = This.PF.pgdocumento.txtCd_VL.Field.FKRecord.Decimali



REPLACE 												;

	QtaResidua 		WITH nNewQtaResidua,		;

	PrezzoTotaleV	WITH DoRig_PrezzoTotaleV(Qta, PrezzoUnitarioV, FattoreScontoTotale, PrezzoAddizionaleV, nDec, 1) ;

	IN DoRig



**	PrezzoTotaleV	WITH xRound(Qta * (PrezzoUnitarioScontatoV + PrezzoAddizionaleV), nDec) ** SAS 3693



ENDPROC

PROCEDURE onrowselchange

LParameters lValue



This.OnRowQtaChange()



ENDPROC

PROCEDURE onrowspesaimportovchange



LOCAL nNewImportoResiduoV



nNewImportoResiduoV = DoRigSpesa.ImportoEvadibileV - DoRigSpesa.ImportoV

nNewImportoResiduoV = IIF(DoRigSpesa.ImportoEvadibileV >= 0, MAX(0, nNewImportoResiduoV), MIN(0, nNewImportoResiduoV))



REPLACE 									;

	ImportoResiduoV	WITH nNewImportoResiduoV;

	IN DoRigSpesa

	

ENDPROC

PROCEDURE onrowspesaselchange

LPARAMETERS xOldValue



IF DoRigSpesa.Selected

	REPLACE DoRigSpesa.ImportoV WITH DoRigSpesa.ImportoEvadibileV IN DoRigSpesa

ELSE

	REPLACE DoRigSpesa.ImportoV WITH 0 IN DoRigSpesa

ENDIF



THISFORM.onRowSpesaImportoVChange()



ENDPROC

PROCEDURE tempdbccreate

LOCAL cTmpDir, cBaseName, oDBCObj



oDBCObj = CreateObject('Empty')

AddProperty(oDBCObj, 'Name', 'TempDBC')



cTmpDir			= oApp.TmpDir + '\'

cBaseName		= SYS(2015)



AddProperty(oDBCObj, 'DBC_BaseName'			, cBaseName)

AddProperty(oDBCObj, 'DBC_Name'				, cTmpDir + cBaseName)

AddProperty(oDBCObj, 'DBF_DOTes'				, cTmpDir + 'DoTesPrel_' 			+ cBaseName + '.dbf')

AddProperty(oDBCObj, 'DBF_DORig'				, cTmpDir + 'DoRigPrel_' 			+ cBaseName + '.dbf')

AddProperty(oDBCObj, 'DBF_DORigSpesa'		, cTmpDir + 'DoRigSpesaPrel_' 	+ cBaseName + '.dbf')

AddProperty(oDBCObj, 'DBF_DORigPackList'	, cTmpDir + 'DoRigPackListPrel_' + cBaseName + '.dbf')



This.AddProperty('TempDBCObject', oDBCObj)



CREATE DATABASE (oDBCObj.DBC_Name)









ENDPROC

PROCEDURE tempdbcdelete

WITH THISFORM.TempDBCObject

	SET DATABASE TO (.DBC_BaseName)

	CLOSE DATABASES	&& Chiude il DBC e tutte le sue tavole

	DELETE DATABASE (.DBC_Name) DELETETABLES

ENDWITH

ENDPROC

PROCEDURE tempdbcload

LPARAMETERS oForm

LOCAL cDbfDoTes, cBaseName, cDbfDoRig, cDbfDoRigSpesa, cDbfDoRigPackList



WITH THIS

	WITH .TempDBCObject

		cDbfDoTes				= .DBF_DOTes

		cDbfDoRig				= .DBF_DORig

		cDbfDoRigSpesa			= .DBF_DORigSpesa

		cDbfDoRigPackList		= .DBF_DORigPackList

		cBaseName				= .DBC_BaseName

	ENDWITH



	SELECT * FROM DOTESxxx ;

	ORDER BY DataDoc	;

	INTO TABLE (cDbfDoTes) DATABASE (cBaseName)

	

	USE		&& Chiudo la WA aperta dalla select into table



	SELECT * FROM DORIGxxx ;

	ORDER BY DataDoc, Riga	;

	INTO TABLE (cDbfDoRig) DATABASE (cBaseName)

	USE		&& Chiudo la WA aperta dalla select into table



	SELECT * FROM DORIGSPESAxxx ;

	ORDER BY DataDoc, Riga	;

	INTO TABLE (cDbfDoRigSpesa) DATABASE (cBaseName)

	USE		&& Chiudo la WA aperta dalla select into table



	SELECT * FROM DORIGPackListxxx ;

	ORDER BY Id_DORIG, Riga	;

	INTO TABLE (cDbfDORIGPackList) DATABASE (cBaseName)

	USE		&& Chiudo la WA aperta dalla select into table



	oForm.PrelLoadRighe(cDbfDOTes, cDbfDORig, cDbfDORigSpesa, cDbfDORigPackList)



ENDWITH

ENDPROC

PROCEDURE preparazionetestatmp

Lparameters cAliasTesteTmp



Local oPgDoc, oTestaDoc

Local lPropDataOra, lPropDataConsegna

Local cTipoDoc, cCd_DOSottocommessa

Local oDoTes_Evadibili As Collection 



oDoTes_Evadibili = CreateObject('Collection')



oPgDoc = This.PF.pgDocumento



Select DOTes



** COMMESSA: controllo se tutti i documenti selezionati hanno la stessa commessa di testa. Se si la riporto nel nuovo doc.

Locate For Selected = .T.

cCd_DOSottocommessa = DOTes.Cd_DOSottocommessa

Scan For DOTes.Selected

	If !SafeCompare(cCd_DOSottocommessa, DOTes.Cd_DOSottocommessa)

		cCd_DOSottocommessa  = Null

		Exit

	EndIf 

EndScan 

** 



If !(Thisform.Mode == 'CREA')

	** Popolo la collection da passare al dittaExt

	oDoTes_Evadibili.Add(Val(Thisform.PF.pgTeste.cmbTestata.Value))			&& per primo ci mette l'id_Dotes selezionato

	Locate For Selected = .T.

	Scan For DOTes.Selected And Id_DOTes != Val(Thisform.PF.pgTeste.cmbTestata.Value)

		oDoTes_Evadibili.Add(DoTes.Id_DoTes)

	EndScan 



	Select DOTes

	Locate For Id_DOTes = Evaluate(Thisform.PF.pgTeste.cmbTestata.Value)

Else

	Go Top

Endif

Scatter Name oTestaDoc Memo



Select (cAliasTesteTmp)

Append Blank



lPropDataOra 		= Evaluate(oPgDoc.cmbCd_DO.FKAlias + '.UIPropDataOra')

lPropDataConsegna = Evaluate(oPgDoc.cmbCd_DO.FKAlias + '.UIPropDataConsegna')

cTipoDoc	 	 		= Evaluate(oPgDoc.cmbCd_DO.FKAlias + '.TipoDocumento')



oTestaDoc.CD_DO				= oPgDoc.cmbCd_DO.Value

oTestaDoc.DOBitMask			= DoTypeAsMask(cTipoDoc, Eval(oPgDoc.cmbCd_DO.FKAlias + '.CliFor'))

oTestaDoc.Cd_CF				= oPgDoc.txtCd_CF.Field.Value

oTestaDoc.NumeroDoc			= ''

oTestaDoc.Id_DOTes			= 0

oTestaDoc.Esecutivo			= oPgDoc.chkEsecutivo.Value

oTestaDoc.Prelevabile		= oPgDoc.chkPrelevabile.Value

oTestaDoc.Modificabile		= oPgDoc.chkModificabile.Value

oTestaDoc.ModificabilePDF	= oTestaDoc.Modificabile

oTestaDoc.DataDoc				= oPgDoc.txtDataDocumento.Field.Value

oTestaDoc.Cd_MGEsercizio	= MGEsercizio(oTestaDoc.DataDoc)

oTestaDoc.Cd_VL				= oPgDoc.txtCd_VL.Field.Value

oTestaDoc.Cambio				= Iif(oTestaDoc.Cd_VL == 'EUR', 1, oPgDoc.txtCd_VL.Field1.Value)

oTestaDoc.DataConsegna 		= Iif(lPropDataConsegna, 					 oTestaDoc.DataDoc, {})

oTestaDoc.TrasportoDataOra = Iif(cTipoDoc $ 'AB' And lPropDataOra, oTestaDoc.DataDoc, {})

oTestaDoc.Vettore1DataOra	= Iif(cTipoDoc $ 'AB' And lPropDataOra, oTestaDoc.DataDoc, {})

oTestaDoc.Vettore2DataOra	= Iif(cTipoDoc $ 'AB' And lPropDataOra, oTestaDoc.DataDoc, {})

oTestaDoc.Cd_MGCausale		= Null



If This.Mode != 'EVADISINGLE'

	oTestaDoc.NumeroDocRif	= Null

	oTestaDoc.DataDocRif		= Null

EndIf  



If This.Mode = 'COPIA'

	** Sistemo i codici SA e SO

	Local oCF_S

	oCF_S = DoTes_Defaults_2Obj(oTestaDoc.CD_DO, oTestaDoc.Cd_CF, oTestaDoc.DataDoc)

	oTestaDoc.Cd_CFDest = oCF_S.Cd_CFDest

	oTestaDoc.Cd_CFSede = oCF_S.Cd_CFSede

EndIf 





oTestaDoc.Cd_DOCommittente			= Null

oTestaDoc.Cd_DOCaricatore			= Null

oTestaDoc.Cd_DOProprietarioMerce = Null



oTestaDoc.Cd_DoSottoCommessa = cCd_DOSottocommessa



** Iva Sospesa

If BitAnd(TD_DOCIVA, oTestaDoc.DOBitMask) != 0 

	Local oCF

	oCF = xSqlExec2Obj('Select IvaSospesa, IvaSplit From CF Where Cd_CF = ' + FormatC4Spt(NEvl(oTestaDoc.Cd_Cf_Fatt, oTestaDoc.Cd_Cf)))

	oTestaDoc.IvaSospesa = oCF.IvaSospesa

	oTestaDoc.IvaSplit   = oCF.IvaSplit	

	

	oTestaDoc.CGCorrispondenzaIvaMerce = xSqlExec2Var('Select CGCorrispondenzaIvaMerce From Preferenza')

EndIf 



** In inserimento di un nuovo Documento, propongo i valori di default per le Extra Info...

Local cExtraInfo

cExtraInfo = ExtraInfo_GetDefaultValue('DoTesExtraInfo')

If !IsEmpty(cExtraInfo)

	AddProperty(oTestaDoc, 'ExtraInfo', cExtraInfo)

EndIf 





If !(Thisform.Mode == 'CREA')

	** --------------------------------------------------

	** Eseguo l'extension OnDOPrel_PopulateNewDoTes() in DittaExt



	If Vartype(oApp.DittaExtCollection) = 'O' And ObjIsA(oApp.DittaExtCollection, 'Collection')

		Local oExt

		For Each oExt In oApp.DittaExtCollection FoxObject

			If PemStatus(oExt, 'OnDOPrel_PopulateNewDoTes', 5)

				oExt.OnDOPrel_PopulateNewDoTes(3, Thisform, oTestaDoc, oDoTes_Evadibili)

			EndIf 

		Next 

	EndIf	



	***</ADDINS>*** --> TODO



	** --------------------------------------------------

EndIf 



Select (cAliasTesteTmp)

Gather Name oTestaDoc Memo

ENDPROC

PROCEDURE preparazionerighetmp

LParameters cAliasRigheTmp, cAliasRigheSpesaTmp, cAliasRighePackListTmp, cAliasTesteTmp



Local oRigaDoc

Local nCounterRighe, nCounterRigheSpesa

Local cScanFor, cDOprel



Local lGenera, cEspressioneRiferimento	&&, lPreleva

Local lRet, xExp



nCounterRighe		= 1

nCounterRigheSpesa	= 1



** Nuovo codice



nID_DOTes = -1



Select DoRig

nLastRec = RecCount()

** Le righe eventualmente aggiunte non vanno riprocessate



Set Order To TesRiga



**Scan For RecNo() <= nLastRec And (Selected)

Scan For Selected

	If nID_DOTes != ID_DOTes

		nID_DOTes = ID_DOTes

		Select DOTES

		Locate For ID_DOTes = nID_DOTes



		lGenera  = .F.

		If InList(ThisForm.Mode, 'EVADI', 'EVADISINGLE')

			ThisForm.SearchOnlstDoc(Cd_DO, @lGenera, @cEspressioneRiferimento)

		EndIf



		If lGenera

			Select DoRig

			nOldRec = RecNo()

			Scatter Name oRigaDoc Memo Blank

			With oRigaDoc

				cDOprel = cEspressioneRiferimento

				If !Empty(cDOprel)

					.ID_DOTES = DOTES.ID_DOTES

					lRet = DoEvalRigaRif(cDOprel, 'DOTES', @xExp)

					If lRet

						.Descrizione = xExp

					Else

						.Descrizione = ''

					EndIf

				EndIf			

				If !IsEmpty(.Descrizione)

					Select (cAliasRigheTmp)

					.TipoRigaRif	= 'R'

					.Riga				= nCounterRighe

					.Evadibile		= .T.

					.Omaggio			= 1

					.Decimali	   = This.PF.pgdocumento.txtCd_VL.Field.FKRecord.Decimali

					.DecimaliPrzUn = This.PF.pgdocumento.txtCd_VL.Field.FKRecord.DecimaliPrzUn

					.ExtraInfo		= Null

					nCounterRighe	= nCounterRighe + 1

					Append Blank

					Gather Name oRigaDoc	Memo

				EndIf

			EndWith			

		EndIf

	EndIf



	Select DoRig

	Scatter Name oRigaDoc Memo

	With oRigaDoc

		If (InList(ThisForm.Mode, 'EVADI', 'EVADISINGLE') And .TipoRigaRif = '' And .QtaEvadibile = .Qta) Or ;&& L'evasione e` fatta per la prima volta e completamente, prelevo anchele matricole

			(		  ThisForm.Mode = 'COPIA' And ThisForm.PF.PgDocumento.chkMATRICOLE.Value)



			** Nothing to do ...

			

		Else

			oRigaDoc.Matricole = Null

		EndIf



		If ThisForm.Mode = 'COPIA' And ThisForm.PF.PgDocumento.chkPacking.Value

			xSqlExec('SELECT * FROM DORigPackList WHERE Id_DoRig = ' + Transform(.ID_DORig), '_PackList')

			Select (cAliasRighePackListTmp)

			Append From (Dbf('_PackList'))

			Use In _PackList

		EndIf



		.ID_DOTES		= DOTES.ID_DOTES

		.Qta				= Iif(.TipoRigaRif = '', .Qta, 0)



		If InList(ThisForm.Mode, 'EVADI', 'EVADISINGLE')

			.ID_DORig_Evade 	= Iif(.TipoRigaRif = '', .ID_DORig	  , 0)

			.QtaEvasa			= Iif(.TipoRigaRif = '', .QtaEvadibile - .QtaResidua, 0)

		Else

			.ID_DORig_Evade 	= Null

			.QtaEvasa			= 0

		EndIf



		.QtaEvadibile	= Iif(.TipoRigaRif = '', .Qta			  , 0)

		.Riga				= nCounterRighe

		

		.TipoRigaRif	= Iif(.TipoRigaRif $ 'rR', 'r', ' ')

		.ExtraInfo		= Null				



		nCounterRighe	= nCounterRighe + 1

		Select (cAliasRigheTmp)

		Append Blank

		Gather Name oRigaDoc	Memo

		Select DORig

	EndWith



	nCounterRighe = nCounterRighe +  1		

EndScan



Select DORigSpesa

Scan For Selected && And ImportoV != 0



	Scatter Name oRigaDoc Memo

	With oRigaDoc

		.ID_DOTES = 0



		If InList(ThisForm.Mode, 'EVADI', 'EVADISINGLE')

			.ID_DORigSpesa_Evade	= .ID_DORigSpesa

			.ImportoEvasoV			= Iif(.ImportoV > .ImportoEvadibileV, .ImportoEvadibileV, .ImportoV)

		Else

			.ID_DORigSpesa_Evade	= Null

			.ImportoEvasoV			= 0

		EndIf



		.ImportoEvadibileV		= .ImportoV

		.Riga							= nCounterRighe

		.ExtraInfo					= Null

		.Perc							= 0



		** Bug 2045

		** .ImportoEvasoV				= .ImportoV_Originale - .ImportoResiduoV 



	EndWith

	nCounterRigheSpesa	= nCounterRigheSpesa + 1

	Select (cAliasRigheSpesaTmp)

	Append Blank

	Gather Name oRigaDoc	Memo

	Select DORigSpesa



EndScan



Return













** Codice originale ****



*With ThisForm

**	lPreleva = ThisForm.PF.PgDocumento.chkPrelevaRigheRif.Value

	Select DOTES

	Local i

	Scan For Selected

		cScanFor = 'Id_DoTes = ' + Tran(Id_DoTes) + " And Selected"

		lGenera  = .F.

		If InList(ThisForm.Mode, 'EVADI', 'EVADISINGLE')

			ThisForm.SearchOnlstDoc(Cd_DO, @lGenera, @cEspressioneRiferimento)

		**	cScanFor = cScanFor + " And !IsEmpty(QtaEvadibile)"

		EndIf



		Select DORig

		Locate For &cScanFor

		If lGenera And Found()

			Scatter Name oRigaDoc Memo Blank

			With oRigaDoc

				cDOprel = cEspressioneRiferimento

				If !Empty(cDOprel)

					.ID_DOTES = DOTES.ID_DOTES

					lRet = DoEvalRigaRif(cDOprel, 'DOTES', @xExp)

					If lRet

						.Descrizione = xExp

					Else

						.Descrizione = ''

					EndIf

				EndIf

				If !IsEmpty(.Descrizione)

					Select (cAliasRigheTmp)

					.TipoRigaRif	= 'R'

					.Riga				= nCounterRighe

					.Evadibile		= .T.

					.Omaggio			= 1

					.Decimali	   = This.PF.pgdocumento.txtCd_VL.Field.FKRecord.Decimali

					.DecimaliPrzUn = This.PF.pgdocumento.txtCd_VL.Field.FKRecord.DecimaliPrzUn

					.ExtraInfo		= Null

					nCounterRighe	= nCounterRighe + 1

					Append Blank

					Gather Name oRigaDoc	Memo

				EndIf

			EndWith

		EndIf



		Select DORig

		Set Order To TesRiga



		Scan For &cScanFor

			Scatter Name oRigaDoc Memo

			With oRigaDoc

				If (InList(ThisForm.Mode, 'EVADI', 'EVADISINGLE') And .TipoRigaRif = '' And .QtaEvadibile = .Qta) Or ;&& L'evasione e` fatta per la prima volta e completamente, prelevo anchele matricole

					(		  ThisForm.Mode = 'COPIA' And ThisForm.PF.PgDocumento.chkMATRICOLE.Value)



					** Nothing to do ...

					

				Else

					oRigaDoc.Matricole = Null

				EndIf



				If ThisForm.Mode = 'COPIA' And ThisForm.PF.PgDocumento.chkPacking.Value

					xSqlExec('SELECT * FROM DORigPackList WHERE Id_DoRig = ' + Transform(.ID_DORig), '_PackList')

					Select (cAliasRighePackListTmp)

					Append From (Dbf('_PackList'))

					Use In _PackList

				EndIf



				.ID_DOTES		= DOTES.ID_DOTES

				.Qta				= Iif(.TipoRigaRif = '', .Qta, 0)



				If InList(ThisForm.Mode, 'EVADI', 'EVADISINGLE')

					.ID_DORig_Evade 	= Iif(.TipoRigaRif = '', .ID_DORig	  , 0)

					.QtaEvasa			= Iif(.TipoRigaRif = '', .QtaEvadibile - .QtaResidua, 0)

				Else

					.ID_DORig_Evade 	= Null

					.QtaEvasa			= 0

				EndIf



				.QtaEvadibile	= Iif(.TipoRigaRif = '', .Qta			  , 0)

				.Riga				= nCounterRighe

				

				.TipoRigaRif	= Iif(.TipoRigaRif $ 'rR', 'r', ' ')

				.ExtraInfo		= Null				

				

				nCounterRighe	= nCounterRighe + 1

				Select (cAliasRigheTmp)

				Append Blank

				Gather Name oRigaDoc	Memo

				Select DORig

			EndWith

		EndScan



		cScanFor = 'ID_DOTes = ' + Tran(DOTES.ID_DOTES) + " AND Selected"



		Select DORigSpesa

		Set Order To TesRiga

		Scan For &cScanFor

			Scatter Name oRigaDoc Memo

			With oRigaDoc

				.ID_DOTES			= 0



				If InList(ThisForm.Mode, 'EVADI', 'EVADISINGLE')

					.ID_DORigSpesa_Evade	= .ID_DORigSpesa

					.ImportoEvasoV			= Iif(.ImportoV > .ImportoEvadibileV, .ImportoEvadibileV, .ImportoV)

				Else

					.ID_DORigSpesa_Evade	= Null

					.ImportoEvasoV			= 0

				EndIf



				.ImportoEvadibileV		= .ImportoV

				.Riga							= nCounterRighe

				.ExtraInfo					= Null

				

				** Bug 2045

				** .ImportoEvasoV				= .ImportoV_Originale - .ImportoResiduoV 



			EndWith

			nCounterRigheSpesa	= nCounterRigheSpesa + 1

			Select (cAliasRigheSpesaTmp)

			Append Blank

			Gather Name oRigaDoc	Memo

			Select DORigSpesa

		EndScan

		Select DOTES

	EndScan

*EndWith



ENDPROC

PROCEDURE searchonlstdoc

LPARAMETERS cSKey, lGenera, cEspressione

LOCAL nTot, i

LOCAL lFound

LOCAL o



lPreleva = .F.

lGenera  = .F.

cEspressione = ''

cSKey = LOWER(cSKey)



WITH THISFORM.PF.pgDocumento.lstDoc

	nTot = .ListCount

	i = 1

	DO WHILE !lFound AND  i <= nTot

		IF LOWER(.List(i, 1)) == cSKey

			lFound		 = .T.

			lGenera      = EVAL(SUBSTR(.List(i, 3), 4, 3))

			cEspressione = SUBSTR(.List(i, 3), 7)

		ENDIF

		i = i + 1

	ENDDO

ENDWITH



RETURN lFound

ENDPROC

PROCEDURE tempdbcdeletetables

WITH THISFORM.TempDBCObject

	SET DATABASE TO (.DBC_BaseName)

	IF FILE(.DBF_DOTes)		

		DROP TABLE (JUSTSTEM(.DBF_DOTes))

		DROP TABLE (JUSTSTEM(.DBF_DORig))

		DROP TABLE (JUSTSTEM(.DBF_DORigSpesa))

		DROP TABLE (JUSTSTEM(.DBF_DORigPackList))

	ENDIF

ENDWITH

ENDPROC

PROCEDURE dobitmask_access



** Posso 'sovrascrivere' This.DoBitMask passandolo come 1^ parametro



Return This.Parameters.ParamGet(1, This.DoBitMask)



ENDPROC

PROCEDURE querydorigpacklist

Lparameters cWhere



If !Empty(cWhere)

	cWhere = Substr(cWhere, 6)

Endif



Local cMacro



TEXT TO cMacro TEXTMERGE NOSHOW

	SELECT

		<<ColumnsList('DORIGPackList', '')>>

	FROM DORIGPackList

	WHERE <<cWhere>>

ENDTEXT



xSqlExec(cMacro, 'DORIGPackList')



ENDPROC

PROCEDURE querydomgcausale

LParameters cWhere



Local cStmt

cWhere = SubStr(cWhere, 6)

Text To cStmt TextMerge Noshow



	Select

		MGCausale.MagPFlag	As MagPFlag,

		MGCausale.Cd_MG_P		As Cd_MG_P,

		MGCausale.UIMagPFix	As UIMagPFix,

		MGCausale.MagAFlag	As MagAFlag,

		MGCausale.Cd_MG_A		As Cd_MG_A,

		MGCausale.UIMagAFix	As UIMagAFix

	From MGCausale

	Inner Join DO On Do.Cd_MGCausale = MGCausale.Cd_MGCausale

	Where << cWhere >>



EndText

Return (xSqlExec(cStmt, 'DoMgCausale') != -1)



ENDPROC

PROCEDURE normmagazzini

Lparameters oRigaDoc



This.oLib.DOPrel_Normalize_MagUb(This.PF.pgDocumento.Cnt_MG.txtCd_MG_P, oRigaDoc)

This.oLib.DOPrel_Normalize_MagUb(This.PF.pgDocumento.Cnt_MG.txtCd_MG_A, oRigaDoc)

ENDPROC

PROCEDURE controllogiacenza

** il codice è stato replicato da fedi_doc



** Contesto: sono posizionato su un record di DORig di cui verificare la quantità in base alla giacenza

** nel caso la quantità non soddisfi i criteri si procede alla modifica interattiva della stessa



Local cAliasDo, cStmt, cEsercizio

Local lChkGiacenza, lchkDisponibile, lChkDisponibileImmediato, lReplaceQta

Local oRec, nRec, oAR

Local nChoice, nNewQta, nTotQta, nTotQtaOld, cCd_MG_P, cCd_AR, cCd_DO, nFattoreToUM1

Local nEsistenzaQ, nDisponibileQ, nDisponibileImmediatoQ



Select DORig



cCd_DO						 = ThisForm.PF.pgDocumento.cmbCd_DO.Value

cAliasDo 					 = ThisForm.PF.pgDocumento.cmbCd_DO.FKAlias

lChkGiacenza			 	 = Eval(cAliasDo + '.UIChkGiacenza')

lchkDisponibile			 = Eval(cAliasDo + '.UIChkDisponibile')

lChkDisponibileImmediato = Eval(cAliasDo + '.UIChkDisponibileImmediato')

cCd_MG_P						 = DoRig.Cd_MG_P

cCd_AR 						 = DoRig.Cd_AR

nNewQta						 = DoRig.Qta

nOldQta						 = DoRig.Qta

nFattoreToUM1				 = DORig.FattoreToUM1		

oAR		 					 = xSqlExec2Obj('Select Fittizio, DBKit From AR Where Cd_AR = ' + FormatC4Spt(cCd_AR)) 	&& Per gli articoli fittizi e Kit non faccio alcun controllo visto che non movimentano il magazzino



If (IsEmpty(cCd_MG_P) Or IsEmpty(nNewQta) Or IsEmpty(cCd_AR) Or (!lChkGiacenza And !lchkDisponibile And !lChkDisponibileImmediato)) Or oAR.Fittizio Or oAr.DBKit

	Return

EndIf



nRec = Recno('DORig')



Calculate Sum(DoRig.Qta * DORig.FattoreToUM1) To nTotQta For DoRig.Cd_MG_P = cCd_MG_P And DoRig.Cd_AR = cCd_AR And DORig.Selected In DORig

nTotQtaOld = 0



Locate Record (nRec)



cEsercizio = ''



Asp_MGEsercizio(This.PF.pgDocumento.txtDataDocumento.Field.Value, @cEsercizio)



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



oRec.EsistenzaQ 				= Max(oRec.EsistenzaQ, 0)

oRec.DisponibileQ 			= Max(oRec.DisponibileQ, 0)

oRec.DisponibileImmediatoQ = Max(oRec.DisponibileImmediatoQ, 0)



lReplaceQta	= .F.



If lChkGiacenza And (oRec.EsistenzaQ < nTotQta)

	cMessage =	Thisform.TB_(,'9E8FB11F-6EAF-40B1-96CB-C4ED06DB4D44', ;

							"Nel documento di tipo <%1!>, la riga dell'articolo %2! presenta una quantità tale che la richiesta sia superiore alla giacenza." + CRLF + ;

							"Magazzino %3! : Quantità riga = %4! / Quantità documento = %5! / Giacenza = %6! [%7!]" + CRLF + CRLF + ;

							"Imposto la quantità in modo tale che la quantità totale non superi la Giacenza?", ;

							 Alltrim(cCd_DO), AllTrim(cCd_AR), Alltrim(cCd_MG_P), Transform(nNewQta), Transform(nTotQta / nFattoreToUM1), Transform(oRec.EsistenzaQ / nFattoreToUM1), Transform(nEsistenzaQ / nFattoreToUM1))



	If xMessageBox(cMessage, MB_ICONQUESTION + MB_YESNO + MB_DEFBUTTON2) == IDYES 

		lReplaceQta = .T.

		nNewQta = Max((oRec.EsistenzaQ - nTotQta) / nFattoreToUM1 + nOldQta, 0)

		nTotQta = nTotQta + (nNewQta - nOldQta) * nFattoreToUM1

		nOldQta = nNewQta

	EndIf 

EndIf



If lchkDisponibile And (oRec.DisponibileQ < nTotQta)

	cMessage =	Thisform.TB_(,'0212F96E-F54D-47EE-B185-AF218D9522F9', ;

							"Nel documento di tipo <%1!>, la riga dell'articolo %2! presenta una quantità tale che la richiesta sia superiore al disponibile." + CRLF + ;

							"Magazzino %3! : Quantità riga = %4! / Quantità documento = %5! / Disponibile = %6! [%7!]" + CRLF + CRLF + ;

							"Imposto la quantità in modo tale che la quantità totale non superi il Disponibile?",	;

						 	Alltrim(cCd_DO), AllTrim(cCd_AR), Alltrim(cCd_MG_P), Tran(nNewQta), Tran(nTotQta / nFattoreToUM1), Tran(oRec.DisponibileQ / nFattoreToUM1), Transform(nDisponibileQ / nFattoreToUM1))



	If xMessageBox(cMessage, MB_ICONQUESTION + MB_YESNO + MB_DEFBUTTON2) == IDYES 

		lReplaceQta = .T.

		nNewQta = Max((oRec.DisponibileQ - nTotQta) / nFattoreToUM1 + nOldQta, 0)

		nTotQta = nTotQta + (nNewQta - nOldQta) * nFattoreToUM1

		nOldQta = nNewQta

	EndIf 

EndIf



If lChkDisponibileImmediato And (oRec.DisponibileImmediatoQ < nTotQta)

	cMessage = Thisform.TB_(,'461C251D-DF6C-49D4-925F-740320E49B7B', 	;

							"Nel documento di tipo <%1!>, la riga dell'articolo %2! presenta una quantità tale che la richiesta sia superiore al disponibile immediato." + CRLF + ;

							"Magazzino %3! : Quantità riga = %4! / Quantità documento = %5! / Disponibile immediato = %6! [%7!]" + CRLF + CRLF + ;

							"Imposto la quantità in modo tale che la quantità totale non superi il Disponibile immediato?" , ;

							Alltrim(cCd_DO), AllTrim(cCd_AR), Alltrim(cCd_MG_P), Tran(nNewQta), Tran(nTotQta / nFattoreToUM1), Tran(oRec.DisponibileImmediatoQ / nFattoreToUM1), Transform(nDisponibileImmediatoQ / nFattoreToUM1))



	If xMessageBox(cMessage, MB_ICONQUESTION + MB_YESNO + MB_DEFBUTTON2) == IDYES 

		lReplaceQta = .T.

		nNewQta = Max((oRec.DisponibileImmediatoQ - nTotQta) / nFattoreToUM1 + nOldQta, 0)

		nTotQta = nTotQta + (nNewQta - nOldQta) * nFattoreToUM1

		nOldQta = nNewQta

	EndIf 

EndIf



If lReplaceQta

	Replace QtaResidua 	With DORig.Qta - nNewQta 	In DORig			&& BUG 2607

	Replace Qta 			With nNewQta 					In DORig



	** BUG 2840: si deve ricalcolare il prezzo totale di riga

*	Replace PrezzoTotaleV With	xRound((DORig.PrezzoUnitarioV * PercStrEvalC(PercStrNormalize(DoRig.ScontoRiga + '+' + DoRig.ScontoAddizionale)) + DORig.PrezzoAddizionaleV) * DORig.Qta, VL.Decimali) ** SAS 3693 



	** SAS 3693 

	Replace PrezzoTotaleV WITH DoRig_PrezzoTotaleV(DORig.Qta, DORig.PrezzoUnitarioV, DORig.FattoreScontoTotale, DORig.PrezzoAddizionaleV, VL.Decimali, 1)	

EndIf





ENDPROC

PROCEDURE setpictureqta

LOCAL cPicQta

LOCAL oRec



oRec = xSqlExec2Obj('Select PicSepQta FROM Preferenza')

IF !ISNULL(oRec)

	cPicQta = oRec.PicSepQta

ELSE

	cPicQta = "#,###,###.####"

ENDIF

WITH THIS.PF.pgRighe.Grid

	.ColQta.InputMask			= cPicQta

	.ColQtaResidua.InputMask	= cPicQta

ENDWITH

WITH THIS.PF.pgInsRighe.Grid

	.ColQta.InputMask			= cPicQta

ENDWITH

WITH THIS.PF.pgSelRigheAvanzata.cntPrelievoQta.Grid

	.ColQta.InputMask = cPicQta

ENDWITH



ENDPROC

PROCEDURE setpictureval

Lparameters cCd_VL 



Local cPicture, cPicture2

Local oPicture

Local nDecPrzUn 



cPicture  = '###########.########'

cPicture2 = '###########.########'

nDecPrzUn = 8



oPicture = xSQLExec2Obj('SELECT PicSep, PicSepPrzUn, DecimaliPrzUn FROM VL WHERE Cd_VL = ' + Format4SPT(cCd_VL))

IF VARTYPE(oPicture) = 'O'

	cPicture  = oPicture.PicSep

	cPicture2 = oPicture.PicSepPrzUn

	nDecPrzUn = oPicture.DecimaliPrzUn 

ENDIF



WITH THISFORM.PF.pgRighe.GridRigheSpesa

	.ColImportoEvadibileV.InputMask	= cPicture

	.ColImportoV.InputMask				= cPicture

	.ColImportoResiduoV.InputMask		= cPicture

ENDWITH



WITH THISFORM.PF.pgRighe.Grid

	.ColPrezzoUnitarioV.InputMask		= cPicture2

	.ColPrezzoAddizionaleV.InputMask	= cPicture2 + ICase(nDecPrzUn < 7, '##', nDecPrzUn = 7, '#', '')

	.ColPrezzoTotaleV.InputMask		= cPicture

ENDWITH



ENDPROC

PROCEDURE inittoolbar

DODEFAULT()



WITH THIS.TOOLBAR

	

	.BUTTONS('ROWSEL'  ).VISIBLE = .T.

	.BUTTONS('ROWUNSEL').VISIBLE = .T.

	

	.Buttons('SEP_AFTER_PREVIEW').Visible = .F.

	.Buttons('EDITREC' ).Visible = .F.

	

ENDWITH

ENDPROC

PROCEDURE Init

DoDefault()



** Verifico che sia agganciato il file Fedi_doc.fxp

SetProcedure('Forms\Fedi_Doc.fxp')



** Controllo dei Contatori per le fatture elettroniche

If Bitand(This.DoBitMask, TD_CA_FATTURA) != 0 Or Bitand(This.DoBitMask, TD_CA_FATTURA_ACC) != 0 Or Bitand(This.DoBitMask, TD_CA_NOTA_ACCREDITO) != 0

	If !Check_CN_FTE()

		Return .F.

	EndIf 

EndIf 



**

This.Caption = This.Caption + ' ' + ProcessDocMode_GetCaption(This.DoBitMask)



This.PF.pgDocumento.cmbCd_DO.DoBitMask 						= This.DoBitMask



If This.PF.pgDocumento.cmbCd_DO.ListCount = 0

	xMessageBox(Thisform.TB_(,'88C336CD-EAC3-42AE-8747-F09FF463F69A', "Nessun tipo di documento configurato. Non è possibile continuare."))

	Return .F.

EndIf



With This.PF.pgGenerale.LV



	.Icons = Thisform.ImageList32

	.ListItems.Add(, 'CREA',  			Thisform.TB_(,'9E576DE8-5F31-4BBB-B2C7-5CC66C207957', 'Crea'),  			'DOCUMENTNEW')

	.ListItems.Add(, 'EVADI', 			Thisform.TB_(,'2BCA35A4-C061-47D5-83CD-CA49CDEB65C5', 'Evadi'), 			'SCHEDARIO12')

**	.ListItems.Add(, 'EVADISINGLE', 	Thisform.TB_(,'5A96463F-07A9-441B-90B5-5AD15D6D7C1E', 'Evadi singolo'), 'SCHEDARIO12')

	.ListItems.Add(, 'COPIA', 			Thisform.TB_(,'1F61EB9B-9AAD-49CC-9FCF-C77110DC8A2D', 'Copia'), 			'SCHEDARIO11')



	.ItemClick(.ListItems(1))



	This.Mode = 'CREA'

	This.PF.pgDocumento.txtCd_VL.Field.SetValue('EUR')

	This.PF.pgDocumento.txtCd_VL.Field1.SetValue(1.0)

Endwith



**	Text To Thisform.PF.pgGenerale.lblWizard.Label.Value NoShow

**	1) Selezionare la modalità di creazione del nuovo documento

**	EndText



**	Text To Thisform.PF.pgDocumento.lblWizard.Label.Value NoShow

**	2) Indicare il tipo di documento che si vuole creare e inoltre indicare i campi della testa del documento

**	EndText



**	Text To Thisform.PF.pgSelTeste.lblWizard.Label.Value NoShow

**	3) Indicare quali documenti saranno oggetto di Prelievo\Copia

**	EndText



**	Text To Thisform.PF.pgTeste.lblWizard.Label.Value NoShow

**	4) Affinare il filtro sulle teste Selezionando\Deselezionando i record e specificare da 

**	   quale delle teste verranno copiati i dati (tranne quelli specificati in precedenza)

**	EndText



**	Text To Thisform.PF.pgSelRighe.lblWizard.Label.Value NoShow

**	5) Indicare quali righe Merce/Spesa dei documenti selezionati saranno oggetto di Prelievo\Copia

**	EndText



**	Text To Thisform.PF.pgRighe.lblWizard.Label.Value NoShow

**	6) Affinare il filtro sulle righe Merce/Spesa Selezionando\Deselezionando i record

**	EndText



**	Text To Thisform.PF.pgInsRighe.lblWizard.Label.Value NoShow

**	3) Inserire le righe che comporranno il documento

**	EndText





With ThisForm.PF



	Iif(!oApp.LicInfo.MG_Main, .pgDocumento.Cnt_MG.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply), .T.)



	If !oApp.LicInfo.DB_Main

		.pgDocumento.chkDistinte.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

		.pgDocumento.chkDistinte.SetValue(.F.)

	EndIf



	If !oApp.LicInfo.DO_LottiMatr

		.pgDocumento.chkMatricole.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

		.pgDocumento.chkMatricole.SetValue(.F.)

		.pgRighe.grid.ColCd_ARLotto.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

		.pgSelRighe.cnt.txtCd_ARLotto.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

	EndIf



	If !oApp.LicInfo.Commesse

		.pgTeste.Grid.ColCd_DOSottoCommessa.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

		.pgSelTeste.cnt.txtCd_DOSottoCommessa.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

		.pgSelRighe.cnt.txtCd_DOSottoCommessa.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

		.pgSelRighe.cnt.txtCd_DOCommessa.ACT_Eng(ACT_S_Set_P, AT_PI_NV_Apply)

	EndIf



EndWith



ThisForm.AddProperty('lCFValidated', .F.)





ENDPROC

PROCEDURE Load

Local cStmt



DoDefault()



This.AddProperty('oLib', NewObject0('AED_Tools', 'Forms\AED_Tools.fxp'))



This.QueryDOTes			(' And 1=0')								&& Crea cursore DoTes

This.QueryDORig			(' And 1=0')								&& Crea cursore DoRig

This.QueryDORigPackList	(' And 1=0')								&& Crea cursore DoRig

This.QueryDORigSpesa		(' And 1=0')								&& Crea cursore DoRigSpesa



** ---------------------------------------------------------------------------------------------

** Cursori per DBC

*This.QueryDOTes			(' And 1=0', 'DOTESxxx')				&& Crea cursore DoTes

*This.QueryDORig			(' And 1=0', 'DORigxxx')				&& Crea cursore DoRig

*This.QueryDORigPackList	(' And 1=0', 'DORigPackListxxx')		&& Crea cursore DoRig

*This.QueryDORigSpesa		(' And 1=0', 'DORigSpesaxxx')			&& Crea cursore DoRigSpesa



Text To cStmt Textmerge NoShow

	Select <<ColumnsList('DOTes')>>, Convert(Bit, 1) As Selected

	From DOTes

	Where 1 = 0

EndText



** --------------------------------------------------

** Eseguo l'extension OnDOPrel_CreateNewDoTes() in DittaExt



If Vartype(oApp.DittaExtCollection) = 'O' And ObjIsA(oApp.DittaExtCollection, 'Collection')

	Local oExt

	For Each oExt In oApp.DittaExtCollection FoxObject

		If PemStatus(oExt, 'OnDOPrel_CreateNewDoTes', 5)

			oExt.OnDOPrel_CreateNewDoTes(3, @cStmt)

		EndIf 

	Next 

EndIf	



***</ADDINS>*** --> TODO



** --------------------------------------------------



xSqlExec(cStmt, 'DOTESxxx')





**

TEXT TO cStmt TEXTMERGE NOSHOW

	SELECT

		Convert(Bit, 1) 					AS Selected,

		<<ColumnsList('DORig')>>,

		0										AS QtaEvasa_InOrigine,

		DORig.Cd_AR							AS DocEvaso_Cd_AR,

		DORig.FattoreToUm1 				AS DocEvaso_FattoreToUM1,

		DORig.Riga							AS DocEvaso_Riga,

		DORig.Cd_DO							AS DocEvaso_Cd_DO,

		DORig.NumeroDoc					AS DocEvaso_NumeroDoc,

		DORig.Qta							AS DocEvaso_Qta,

		ISNULL(DORig.QtaEvadibile, 0) AS DocEvaso_QtaEvadibile,

		DORig.Cd_ARMisura					AS DocEvaso_Cd_ArMisura,

		DORig.DataDoc 						AS DocEvaso_DataDoc,

		DORig.QtaEvadibile 				AS QtaResidua,

		DORig.Cd_ARMisura					AS Cd_ARMisura_RE,

		DORig.FattoretoUM1 				AS FattoretoUM1_RE,

		(CASE DORig.FattoretoUM1 WHEN 0 THEN 0	ELSE DORig.PrezzoUnitarioV / DORig.FattoretoUM1 END ) AS PrezzoUnitarioV_UM

	FROM DORig

	WHERE 1=0

	ORDER BY DORig.Id_DOTes, DORig.Riga

ENDTEXT

xSqlExec(cStmt, 'DORigxxx')



TEXT TO cStmt TEXTMERGE NOSHOW

	Select <<ColumnsList('DORIGPackList', '')>>

	FROM DORIGPackList

	WHERE 1=0

ENDTEXT

xSqlExec(cStmt, 'DORigPackListxxx')



Text To cStmt TextMerge NoShow

	SELECT

		Convert(BIT, 1) AS Selected,

		<<ColumnsList('DORigSpesa')>>,

		DORigSpesa.ImportoV AS ImportoV_Originale,

		DOTes.Cd_CF,

		DOTes.Cd_DO,

		DOTes.NumeroDoc,

		DoRigSpesa.ImportoEvasoV * 0 		AS ImportoResiduoV,

		/* I CAMPI CHE MI SERVONO PER IL CALCOLO DELL'EVASO NEI WIZARD */

		DORigSpesa.ImportoEvasoV 			AS ImportoEvasoV_InOrigine,

		DORigSpesa.ImportoEvadibileV 		AS DocEvaso_ImportoEvadibileV,

		DORigSpesa.ImportoV 					AS DocEvaso_ImportoV		

	FROM DORigSpesa INNER JOIN DOTes ON DOTes.Id_DOTes = DORigSpesa.ID_DOTes

	WHERE 1=0

EndText

xSqlExec(cStmt, 'DORigSpesaxxx')



** ---------------------------------------------------------------------------------------------

** Cursore per Lista Articoli per Quantità

TEXT To cStmt NoShow

	Select

		AR.Cd_AR						As Cd_AR,

		AR.Descrizione				As Descrizione,

		ARARMisura.Cd_ARMisura	As Cd_ARMisura,

		DORig.Qta					As Qta,

		DORig.FattoreToUM1		As UMFatt

	From DORig

	Inner Join AR 			 On DORig.Cd_AR = AR.Cd_AR

	Inner Join ARARMisura On    AR.Cd_AR = ARARMisura.Cd_AR And ARARMisura.DefaultMisura = 1

	Where 1=0

ENDTEXT

xSqlExec(cStmt, 'ARQta')



** ---------------------------------------------------------------------------------------------

** Impostazioni

TEXT To cStmt NoShow

	Select

		I.Cd_CGConto_1		As Cd_CGConto_Acq,

		I.Cd_CGConto_2		As Cd_CGConto_Ven,

		I.Cd_Aliquota_1	As Cd_Aliquota_Acq,

		I.Cd_Aliquota_2	As Cd_Aliquota_Ven

	From Impostazione I

	Where I.Cd_Impostazione = 'DEFAULT_RIGHE_DOC'

ENDTEXT

xSqlExec(cStmt, 'Impostazione')



ENDPROC

PROCEDURE cmdrowsel

LPARAMETERS xForce



LOCAL oPage, nRecNo



IF VARTYPE(xForce) = 'L'

	oPage = THIS.PF.CurrentPage

ELSE

	oPage = THIS.PF.pgRighe

ENDIF	



IF LOWER(oPage.Name) = 'pgteste'

	SELECT DoTes

	nRecNo = RecNo()

	oPage.Grid.SaveRecordSource()

	REPLACE ALL Selected WITH .T.

	LOCATE RECORD (nRecNo)

	oPage.Grid.RestoreRecordSource()

	oPage.cmbTestata.Requery()

	

	RETURN

ENDIF



IF LOWER(oPage.Name) = 'pgrighe' AND (TYPE('THISFORM.ActiveControl') == 'O' OR VARTYPE(xForce) == 'N')

	LOCAL cOrder

	WITH THIS

		.MousePointer = MOUSE_HOURGLASS

		.LOCKSCREEN = .T.

	ENDWITH	

	IF (VARTYPE(xForce) == 'N' AND xForce = 1) OR THISFORM.ActiveControl.name == 'Grid'

		WITH oPage.grid

			.SaveRecordSource()

			SELECT DORig

			nRecNo = RecNo()

			WITH .ColSelected.StdCheck1

				SCAN 

					IF !Selected

						REPLACE Selected WITH .T.

						THISFORM.OnRowSelChange(.T.)

					ENDIF	

				ENDSCAN

			ENDWITH

			.RestoreRecordSource()

			.Refresh()

			LOCATE RECORD (nRecNo)

		ENDWITH

	ELSE

		IF (VARTYPE(xForce) == 'N' AND xForce = 2) OR THISFORM.ActiveControl.name == 'GridRigheSpesa'

			WITH oPage.gridRigheSpesa

				SELECT DoRigSpesa

				nRecNo = RecNo()

				WITH .ColSelected.StdCheck1

					SCAN 

						IF !Selected

							REPLACE Selected WITH .T.

							THISFORM.OnRowSpesaSelChange(.T.)

						ENDIF

					ENDSCAN

				ENDWITH

				LOCATE RECORD (nRecNo)

			ENDWITH

		ENDIF

	ENDIF

	WITH THIS

		.LOCKSCREEN = .F.

		.MousePointer = MOUSE_DEFAULT

		oPage.Grid.Refresh()

		oPage.GridRigheSpesa.Refresh()

	ENDWITH

ENDIF







ENDPROC

PROCEDURE cmdrowunsel

LPARAMETERS xForce



LOCAL oPage, nRecNo



IF VARTYPE(xForce) = 'L'

	oPage = THIS.PF.CurrentPage

ELSE

	oPage = THIS.PF.pgRighe

ENDIF	



IF LOWER(oPage.Name) = 'pgteste'

	SELECT DoTes

	nRecNo = RecNo()

	oPage.Grid.SaveRecordSource()

	REPLACE ALL Selected WITH .F.

	LOCATE RECORD (nRecNo)

	oPage.Grid.RestoreRecordSource()

	oPage.cmbTestata.Requery()

	RETURN

ENDIF



IF LOWER(oPage.Name) = 'pgrighe' AND (TYPE('THISFORM.ActiveControl') == 'O' OR VARTYPE(xForce) == 'N')

	LOCAL cOrder

	WITH THIS

		.MousePointer = MOUSE_HOURGLASS

		.LOCKSCREEN = .T.

	ENDWITH	

	IF (VARTYPE(xForce) == 'N' AND xForce = 1) OR THISFORM.ActiveControl.name == 'Grid'

		WITH oPage.grid

			.SaveRecordSource()

			SELECT DORig

			nRecNo = RecNo()

			WITH .ColSelected.StdCheck1

				SCAN 

					IF Selected

						REPLACE Selected WITH .F.

						THISFORM.OnRowSelChange(.F.)

					ENDIF	

				ENDSCAN

			ENDWITH

			.RestoreRecordSource()

			.Refresh()

			LOCATE RECORD (nRecNo)

		ENDWITH

	ELSE

		IF (VARTYPE(xForce) == 'N' AND xForce = 2) OR THISFORM.ActiveControl.name == 'GridRigheSpesa'

			WITH oPage.gridRigheSpesa

				SELECT DoRigSpesa

				nRecNo = RecNo()

				WITH .ColSelected.StdCheck1

					SCAN 

						IF Selected

							REPLACE Selected WITH .F.

							THISFORM.OnRowSpesaSelChange(.F.)

						ENDIF

					ENDSCAN

				ENDWITH

				LOCATE RECORD (nRecNo)

			ENDWITH

		ENDIF

	ENDIF

	WITH THIS

		.LOCKSCREEN = .F.

		.MousePointer = MOUSE_DEFAULT

		oPage.Grid.Refresh()

		oPage.GridRigheSpesa.Refresh()

	ENDWITH

ENDIF



ENDPROC

PROCEDURE fine

Local oForm, oRecAR, oRec, oDef

Local cStmt, cCmd

Local nDec, nDecPrzUn



If (Thisform.Mode == 'CREA')

	Select DOTes

	Zap

	Append Blank



	oRec = DoTes_Defaults_2Obj(This.PF.pgdocumento.cmbCd_DO.Value, This.PF.pgdocumento.txtCd_CF.Field.Value, This.PF.pgdocumento.txtDataDocumento.Field.Value)



	Replace;

		Selected 			With .T.,;

		Cd_DO 				With oRec.Cd_DO,;

		ImportiIvati		With oRec.ImportiIvati,;

		CD_CF 				With oRec.CD_CF,;

		DataDoc 				With oRec.DataDoc,;

		Cd_CF_Fatt			With oRec.Cd_CF_Fatt,;

		Cd_PG 				With oRec.Cd_PG,;

		Cd_LS_1				With oRec.Cd_LS_1,;

		Cd_LS_2				With oRec.Cd_LS_2,;

		Cd_LS_C				With oRec.Cd_LS_C,;

		Cd_VL 				With oRec.Cd_VL,;

		Cambio 				With oRec.Cambio,;

		Iban					With oRec.Iban, ;

		BicCode				With oRec.BicCode, ;

		Cd_CGConto_Banca	With oRec.Cd_CGConto_Banca,;

		CD_ReverseCharge	With oRec.CD_ReverseCharge,;

		ScontoCassa			With oRec.ScontoCassa,;

		Cd_CFZona			With oRec.Cd_CFZona,;

		Cd_Agente_1			With oRec.Cd_Agente_1,;

		Cd_Agente_2			With oRec.Cd_Agente_2,;

		Cd_CFDest			With oRec.Cd_CFDest,;

		Cd_CFSede			With oRec.Cd_CFSede,;

		Cd_DOTrasporto 	With oRec.Cd_DOTrasporto,;

		Cd_DOAspBene	 	With oRec.Cd_DOAspBene,;

		Cd_DOSped 			With oRec.Cd_DOSped,;

		Cd_DOPorto 			With oRec.Cd_DOPorto,;

		Cd_DOVettore_1 	With oRec.Cd_DOVettore_1,;

		Cd_DOVettore_2 	With oRec.Cd_DOVettore_2,;

		Cd_MGCausale 		With oRec.Cd_MGCausale,	;

		DataConsegna		With oRec.DataConsegna, ;

		TrasportoDataOra	With oRec.TrasportoDataOra ;

		In DOTes





	If Inlist(Eval(This.PF.pgdocumento.cmbCd_DO.FKAlias + '.TipoDocumento'), 'F', 'A', 'N', 'B', 'O')

		Replace;

			Iban 					With This.PF.pgdocumento.txtCd_CF.Field.FKRecord.Iban,;

			BicCode 				With This.PF.pgdocumento.txtCd_CF.Field.FKRecord.BicCode,;

			Cd_CGConto_Banca 	With This.PF.pgdocumento.txtCd_CF.Field.FKRecord.Cd_CGConto_Banca

	Endif



	oRec = DoTes_Defaults_Sconto_2Obj(DOTes.Cd_DO, DOTes.CD_CF, DOTes.Cd_CFDest, DOTes.Cd_Agente_1, DOTes.Cd_Agente_2, DOTes.Cd_PG)



	Replace ScontoCassa With oRec.ScontoCassa



	Select DORig

	Scan



		If !Empty(Cd_AR)

			oRecAR = xSqlExec2Obj('SELECT ' + ColumnsList('AR', '') + ' FROM AR WHERE Cd_AR = ' + Format4Spt(Cd_AR))



			oRec = DoRig_Defaults_2Obj(;

				DOTes.Cd_DO, ;

				DOTes.CD_CF, ;

				DOTes.DataDoc, ;

				DoRig.DataConsegna,	;

				DOTes.Cd_CFDest, ;

				DOTes.Cd_Agente_1, ;

				DOTes.Cd_Agente_2, ;

				DOTes.Cd_PG, ;

				DOTes.Cd_LS_1, ;

				DOTes.Cd_LS_2, ;

				DOTes.Cd_VL, ;

				DOTes.Cambio, ;

				DORig.Cd_AR, ;

				DORig.Qta, ;

				DORig.Cd_ARMisura, ;

				DORig.FattoreToUM1, ;

				DORig.Cd_DOSottoCommessa)

				

			Thisform.NormMagazzini(oRec)



			Replace ;

				Selected						With .T.,							;

				;

				Cd_ARMisura					With oRec.Cd_ARMisura,			;

				FattoreToUM1				With oRec.FattoreToUM1,			;

				;

				Cd_CGConto 					With oRec.Cd_CGConto,			;

				Cd_Aliquota 				With oRec.Cd_Aliquota,			;

				Cd_CAVda						With oRec.Cd_CAVda,				;

				Cd_CACda						With oRec.Cd_CACda,				;

				Cd_CAFormula				With oRec.Cd_CAFormula,			;

				CAPartenza					With oRec.CAPartenza,			;

				CADurata						With oRec.CADurata,				;

				PrezzoUnitarioV			With oRec.Prezzo,					;

				PrezzoAddizionaleV		With oRec.PrezzoAddizionale,	;

				Id_LSArticolo	   		With oRec.Id_LSArticolo,		;

				Id_LSScaglione				With oRec.Id_LSScaglione,		;

				DecimaliPrzUn				With oRec.DecimaliPrzUn,		;

				Decimali						With oRec.Decimali,				;

				ScontoRiga					With oRec.Sconto,					;

				ScontoAddizionale			With oRec.ScontoAddizionale,	;

				FattoreScontoTotale		With 1 - PercStrEvalC(PercStrNormalize(oRec.Sconto + '+' + oRec.ScontoAddizionale)), ;

				ProvvigioneRiga_1			With oRec.Provvigione_1,		;

				ProvvigioneRiga_2			With oRec.Provvigione_2,		;

				Evadibile					With oRec.Evadibile,				;

				;

				Cd_MG_P						With oRec.Cd_MG_P,				;

				Cd_MGUbicazione_P			With oRec.Cd_MGUbicazione_P,	;				

				Cd_MG_A						With oRec.Cd_MG_A,				;

				Cd_MGUbicazione_A			With oRec.Cd_MGUbicazione_A,	;				

				;

				Descrizione					With oRecAR.Descrizione,		;

				QtaEvasa						With DORig.Qta - (DORig.QtaResidua * DORig.FattoreToUM1_RE),;

				QtaEvadibile				With DORig.Qta,					;

				QtaEvasa_InOrigine		With 0, 								;

				Cd_ARLotto					With '',								;

				PrezzoUnitarioV_UM		With xDefault(oRec.Prezzo, 0) / oRec.FattoreToUM1 ;

				;

				In DORig



				** Lo stacco dal blocco sopra, perchè così ho a disposizione il valore in DORig.FattoreScontoTotale senza ricalcolarlo con la funzione PercStrEvalC()

				Replace PrezzoUnitarioScontatoV With xRound(DORig.PrezzoUnitarioV * DORig.FattoreScontoTotale, DORig.DecimaliPrzUn) In DORig



				** In questa fase non perdo tempo a calcolare il PrezzoTotaleV perchè lo fa questo metodo un po' più sotto...

				**	PrezzoTotaleV 			WITH DoRig_PrezzoTotaleV(oRec.Qta, oRec.Prezzo,  (1 - PercStrEvalC(PercStrNormalize(oRec.Sconto + '+' + oRec.ScontoAddizionale))), oRec.PrezzoAddizionale, oRec.Decimali, 1) ;





				** TODO: sistemare dati dei ratei e risconti:

				**					** ----- LICADAPTER

				**					If oApp.LicInfo.CG_Main

				**						oDef = RR_GetDefaults_DO(DoTes.Cd_DO, DORig.Cd_CGConto, DOTes.DataDoc)

				**						** Se il conto è vuoto lo prendo dalle impostazioni

				**						If oDef.RR_Enabled And IsEmpty(oDef.RR_Cd_CGConto)

				**							oDef.RR_Cd_CGConto = RR_GetConto(Null, DOTes.DataDoc, DORig.RR_DataInizio, DORig.RR_DataFine, Null, Null)

				**						EndIf



				**						Replace	RR_Cd_CGConto 	With oDef.RR_Cd_CGConto,	;

				**									RR_DataInizio 	With oDef.RR_DataInizio,	;

				**									RR_DataFine   	With oDef.RR_DataFine   In DORig

				**					EndIf



				**					** Mi serve valorizzato anche il campo sezionebilancio dai conti per l'utilizzo in Ctrls_When().

				**					** Funziona anche con par null/blank ma per non perdere tempo imposto direttamente null

				**					oDef = Iif(IsEmpty(DoRig.Cd_CGConto), Null, xSQLExec2Obj(Textmerge('Select SezioneBilancio, ContoMerceSpesa From CGConto Where Cd_CGConto = <<FormatC4SPT(DoRig.Cd_CGConto)>>')))

				**					Replace 	ContoMerceSpesa 	With Iif(IsNull(oDef), 0,  oDef.ContoMerceSpesa)	In DoRig



		Else



			nDec     	= This.PF.pgdocumento.txtCd_VL.Field.FKRecord.Decimali

			nDecPrzUn 	= This.PF.pgdocumento.txtCd_VL.Field.FKRecord.DecimaliPrzUn



			Replace 														;

				Decimali						With nDec				;

				DecimaliPrzUn				With nDecPrzUn			;

				In DORig



		Endif



	Endscan



	xSqlExec('Select * From dbo.DO_SpeseVarie(' + Format4Spt(DOTes.Cd_DO) + ', ' + Format4Spt(DoTes.Cd_CF) + ', ' + Format4Spt(DoTes.Cd_CFDest) + ', ' + Format4Spt(DOTes.Cambio) + ', ' + Format4Spt(This.PF.pgdocumento.txtCd_VL.Field.FKRecord.Decimali) + ')', 'DOSpesa')



	If Used("DOSpesa")

		Select DOSpesa

		Scan

			Scatter Name oDoSpesa Memo

			AddProperty(oDoSpesa, 'Selected', .T.)

			Select DORigSpesa

			Append Blank

			Gather Name oDoSpesa	Memo

			Select DOSpesa

		Endscan

		Use In DOSpesa

	Endif



	Tableupdate(2,.T.,'DOTES')

	Tableupdate(2,.T.,'DORIG')

	Tableupdate(2,.T.,'DORIGSPESA')



EndIf



**

Select DORig

** L'ordine di prelievo lo faccio in base alla cmdOrderBy

 cCmd = 'Index On ' + This.PF.pgTeste.cmbOrderBy.ListItem(This.PF.pgTeste.cmbOrderBy.ListIndex, 2) + ' Tag TesRiga  Collate "Machine"'

&cCmd

Index On Selected Tag Selected Collate "Machine"



** SAS 3434: vedo se ci sono date di consegna inferiori alla data del documento da correggere....

If This.PF.pgDocumento.chkDataConsegna.Value Or Thisform.Mode == 'COPIA'

	Replace DataConsegna With This.PF.pgDocumento.txtDataDocumento.Field.Value In DoRig For DoRig.Selected And !IsEmpty(DoRig.DataConsegna) And DoRig.DataConsegna < This.PF.pgDocumento.txtDataDocumento.Field.Value

	Go Top In DoRig

EndIf 

** SAS 3434



Scan For Selected



	** ----- LICADAPTER

	If oApp.LicInfo.MG_Main

		Thisform.ControlloGiacenza()

	EndIf

	

	** BUG 2840: si deve ricalcolare il prezzo totale di riga

	** SAS 3693 

	Replace PrezzoTotaleV WITH DoRig_PrezzoTotaleV(DORig.Qta, DORig.PrezzoUnitarioV , DORig.FattoreScontoTotale, DORig.PrezzoAddizionaleV, VL.Decimali, 1) 



Endscan



Select DORigSpesa

** L'ordine di prelievo lo faccio in base alla cmdOrderBy

&cCmd

Index On Selected Tag Selected Collate "Machine"



*|	AGGIORNO I CAMPI CHE MI SERVONO PER IL CALCOLO DELL'EVASO NEI WIZARD */

Scan For Selected

	REPLACE 		 ImportoEvasoV_InOrigine	 WITH DORigSpesa.ImportoEvasoV ;

					,DocEvaso_ImportoEvadibileV WITH DORigSpesa.ImportoEvadibileV ;

					,DocEvaso_ImportoV			 WITH DORigSpesa.ImportoV 			;

		IN DORigSpesa

endscan

Go Top 



Select DoTes



** ATTENZIONE: le form viene lanciata con la FixedWhere  "1=0"  per evitare di caricare

** l'elenco, operazione che nel caso di ditte grosse può essere molto pesante; in basso

** a destra allora la scritta "Record 1/1" che in questo caso va benissimo lo stesso



oForm = RunFediDoc(Cd_Do, Left(Cd_CF,1), This.DoBitMask, Thisform, "1=0")



If Vartype(oForm) != 'O'

	xMessageBox(MSG_POLICY_DENYFRM, MB_OK + MB_ICONSTOP)

	Return .F.

Endif

oForm.ModeFromPrelievo = 1 && Simulo prelievo automatico!

oForm.HideOnClose = .T.



** In caso di zoom attivo, devo ripristinare la larghezza delle colonne, altrimenti me le trovo aumentate perchè succede questa serie di eventi:

** - si avvia la fedi_doc nascosta

** - nell'init del pgRighe.cnt viene fatto il layouset della grid (quindi le colonne vengono allargate)

** - nel .Show() qua sotto il font delle colonne viene aumentato, e le colonne si allargato

AddProperty(oForm, 'RestoreColumnsWidthToLayoutSet', .T.)



**

If Empty(oForm.cmdNew())

	xMessageBox(MSG_POLICY_DENYOP, MB_OK + MB_ICONSTOP)

	oForm.Release()

	Return .F.

Endif

Select DOTESxxx

Zap





Thisform.AddProperty('oFedi_Doc', oForm)			&& richiesta del CA per avere la Fedi_Doc disponibile nell'entry point OnDOPrel_PopulateNewDoTes()

Thisform.PreparazioneTestaTmp('DOTESxxx')

RemoveProperty(Thisform, 'oFedi_Doc')



Select DORIGxxx

Zap



Select DORIGSPESAxxx

Zap



Select DORIGPACKLISTxxx

Zap



Thisform.PreparazioneRigheTmp('DORIGxxx', 'DORIGSPESAxxx', 'DORIGPACKLISTxxx', 'DOTESxxx')



Tableupdate(2, .T., 'DOTESxxx')

Tableupdate(2, .T., 'DORIGxxx')

Tableupdate(2, .T., 'DORIGSpesaxxx')

Tableupdate(2, .T., 'DORIGPackListxxx')



** PA_Options viene modificato dalla form do_tes se necessario!

With oForm

	.PF.pgGenerale.txtCd_DO.Field.SetValue(Thisform.PF.pgdocumento.cmbCd_DO.Value)

	.PF.pgGenerale.txtCd_DO.Field.Enabled = .F.

	.PF.pgGenerale.txtCd_CF.Field.Enabled = .F.



	Thisform.TempDBCCreate()

	Thisform.TempDBCDeleteTables()

	Thisform.TempDBCLoad(oForm)

	

	** BUG 3495 

	oForm.SetRegimeIva('USERINTERFACE')

	**



	If Thisform.Mode = 'COPIA'

		If Thisform.PF.pgdocumento.chkDistinte.Value

			.cmdDODBNewDup()

		Else

			.DE.DORig.RunCmd('Replace All Id_DODB With Null In DORig')

		Endif

	Endif



	** Devo ricaricare il controllo delle Note Multiple

	.PF.pgGenerale.PF.pgInfo.EdtNotePiede.LoadNoteFromXml()



	.PF.ActivePage = 2	

	.Refresh()

	.PF.pgGenerale.PF.pgRighe.Cnt.Grid.SaveRecordSource()

	.DE.DORig.GoTop()

	.PF.pgGenerale.PF.pgRighe.Cnt.Grid.RestoreRecordSource()



	**

	.PF.pgGenerale.cntTesta2.Refresh(.T.)		&& lRefreshLblLabel = .T. serve solo per visualizzare/nascondere la lblAlert



	**

	If .Toolbar.Buttons('FTEXML').Enabled

		** devo impostare, per i clienti CONDOMINIO, il tipo reditto

		If .PF.pgGenerale.txtCd_CF.Field.FKRecord.Condominio

			Local oXml, oNode, oRecDoTes

			oRecDoTes = .DE.DoTes.Scatter()		

			oXml = NewDomDocument(NEvl(oRecDoTes.Fte_Xml, '<rows><row/></rows>'))

			oNode = oXml.SelectSingleNode('rows/row')

			oNode.setAttribute('dg_causalepagamento', NEvl(xSqlExec2Var('Select Cd_TipoReddito From RAAnagrafe Where Cd_CF = ' + FormatC4Spt(.PF.pgGenerale.txtCd_CF.Field.Value)), ''))

			.DE.DoTes.RunCmd('Replace Fte_Xml With ' + FormatC4Spt(Strtran(oXml.Xml, CRLF, '')))

		EndIf 

	EndIf

	

	**

	.Show(1)

	.Release()

Endwith



If xMessageBox(Thisform.TB_(, "031EDE7B-FB58-477B-8D05-3610853C4E8C", 'Vuoi uscire dalla procedura?'), 4+32) = 6	&& YES

	This.cmdExit()

Else

	Thisform.PF.pgRighe.grid.SaveRecordSource()

	Thisform.QueryDORigPackList (' And 1=0') && Crea cursore DoRigPackList

	Thisform.PF.pgRighe.grid.RestoreRecordSource()

	

	Thisform.PF.pgRighe.gridRigheSpesa.SaveRecordSource()

	Thisform.QueryDORigSpesa (' And 1=0') && Crea cursore DoRigSpesa

	Thisform.PF.pgRighe.gridRigheSpesa.RestoreRecordSource()



	This.PF.ActivePage = 2

	This.StepEnabler()

	This.Refresh()

	

EndIf 



ENDPROC

PROCEDURE querynavigate

LParameters nCurActivePage, nNewActivePage



If nCurActivePage = 2 And nNewActivePage >= 3

	Local lUseMG_P, lUseMG_A

	Local oDO, oCF



	With ThisForm.PF.pgDocumento

		If .txtCd_CF.Field.IsEmpty()

**				xMessageBox(Thisform.TB_(,'9C905FAE-6FF4-47FC-ADBA-EBADF04232C9', 'Indicare il codice Cliente/Fornitore !!'), MB_ICONSTOP)

			DO CASE

				CASE .txtCd_CF.Field.FkMode=1

					xMessageBox(Thisform.TB_(,'4B313C56-9EC0-48EA-B80A-FEF03B13E3C7', 'Indicare il codice Cliente !!'), MB_ICONSTOP)

				CASE .txtCd_CF.Field.FkMode=2

					xMessageBox(Thisform.TB_(,'E4AB041C-5C19-46FA-914C-4AED34D9C08D', 'Indicare il codice Fornitore !!'), MB_ICONSTOP)

				OTHERWISE

					xMessageBox(Thisform.TB_(,'9C905FAE-6FF4-47FC-ADBA-EBADF04232C9', 'Indicare il codice Cliente/Fornitore !!'), MB_ICONSTOP)

			ENDCASE

			Return .F.

		ENDIF



		If .lstDoc.Visible

			ThisForm.WCDocFilter = ThisForm.GetDocPreList()

			If Empty(This.WCDocFilter)

				xMessageBox(Thisform.TB_(,'B29D1653-F323-4C96-B302-D6CECD58A013', 'Indicare almeno un Documento da Prelevare !!'), MB_ICONSTOP)

				Return .F.

			EndIf

		EndIf



		** Fattura Elettronica	

		If oApp.LicInfo.FatturaElettronica

		

			oDO = xSqlExec2Obj('Select DO.TipoDocumento, CN.FatturaElettronica From CN Join DO On CN.Cd_CN = DO.Cd_CN Where DO.Cd_DO = ' + FormatC4Spt(.cmbCd_DO.Value))

			

			If InList(oDO.TipoDocumento, 'F', 'A', 'N') And !oDO.FatturaElettronica

				** Fatture non Elettroniche

				Local cStmt

				Text To cStmt TextMerge NoShow

					Select 

						EntePubblico 			= Case When CF.Cd_CF_Fatt Is Null Then CF.EntePubblico 			Else CF_Fatt.EntePubblico 			End, 

						CodiceIPA	 			= Case When CF.Cd_CF_Fatt Is Null Then CF.CodiceIPA 	  			Else CF_Fatt.CodiceIPA				End, 

						CodiceFPR	 			= Case When CF.Cd_CF_Fatt Is Null Then CF.CodiceFPR				Else CF_Fatt.CodiceFPR 				End, 

						FE_Ignore_CodiceFPR  = Case When CF.Cd_CF_Fatt Is Null Then CF.FE_Ignore_CodiceFPR	Else CF_Fatt.FE_Ignore_CodiceFPR	End

					From CF 

						Left Join CF CF_Fatt On CF.Cd_CF_Fatt = CF_Fatt.Cd_CF 

					Where 

						CF.Cd_CF = << FormatC4Spt(.txtCd_CF.Field.Value) >>

				EndText 

				oCF = xSqlExec2Obj(cStmt)

				Do Case

					Case  oCF.EntePubblico And !IsEmpty(oCF.CodiceIPA)

						xMessageBox(Thisform.TB_(,'04B3F782-9CCA-4213-8EAF-F03540052E33', 'Un Ente Pubblico provvisto di "Codice Ufficio" non può essere usato su una Fattura non elettronica.'), 16)

						.txtCd_CF.Field.SetFocus()

						Return .F.

					Case !oCF.EntePubblico And !IsEmpty(oCF.CodiceFPR) And !oCF.FE_Ignore_CodiceFPR

						xMessageBox(Thisform.TB_(,'E10070D5-900C-44A1-B8DB-A31E3B627C6D', 'Un cliente privato provvisto di "Codice Dest/PEC B2B" non può essere usato su una Fattura non elettronica.'), 16)

						.txtCd_CF.Field.SetFocus()

						Return .F.

				EndCase

			EndIf

		EndIf 



	EndWith

	

	** ----- LICADAPTER

	If oApp.LicInfo.MG_Main

		If !ThisForm.PF.pgDocumento.Cnt_MG.txtCd_MG_P.IsValid() Or !ThisForm.PF.pgDocumento.Cnt_MG.txtCd_MG_A.IsValid()

			Return .F.

		EndIf

	EndIf

EndIf



** If nCurActivePage = 4 And nNewActivePage = 5

If nCurActivePage = 4 And (nNewActivePage >= 5)



	If Thisform.Mode == 'EVADISINGLE'



		Local nOldWA, nRec, nCount

		

		nOldWA = Select()

		

		Select DoTes

		nRec = Recno()



		If Eof()

			** Non ci sono record selezionato... no faccio nulla

			Select (nOldWA)

			Return .F.

		EndIf 



		Count To nCount For Selected

		

		Go (nRec)

		Select (nOldWA)



		If nCount !=1

			xMessageBox(Thisform.TB_(,'1C35D174-1D18-4B67-8782-F3DD0193BC83', 'È necessario selezionare una sola Testa Documento !!'), MB_ICONSTOP)

			Return .F.		

		EndIf 

	Else

		With ThisForm .PF.pgDocumento

			If RecCount('_cmbDoTestata')=0

				xMessageBox(Thisform.TB_(,'003F3D0C-974D-4F50-BFDE-808F7ABC4BB6', 'Deve essere selezionata almeno una Testa Documento !!'), MB_ICONSTOP)

				Return .F.

			EndIf

		EndWith

	

	EndIf 

EndIf





ENDPROC

PROCEDURE layoutload

DoDefault()



This.PF.pgDocumento.chkDataConsegna.Value = This.UserPrefGetProperty(This.PF.pgDocumento.chkDataConsegna, UP_SCOPE_COMPUSER, 'chkDataConsegna', .F.)

ENDPROC

PROCEDURE layoutsave

DoDefault()



This.UserPrefSetProperty(This.PF.pgDocumento.chkDataConsegna, UP_SCOPE_COMPUSER, 'chkDataConsegna', This.PF.pgDocumento.chkDataConsegna.Value)

ENDPROC

PROCEDURE PF.pgSelRigheAvanzata.Activate

DoDefault()

This.cntPrelievoQta.chkSoloArticoliPerQuantita.Click()

ENDPROC

PROCEDURE PF.onpageactivate

LParameters oPage, nOldPage, lJustRefreshed



Local cPageName



cPageName = Lower(oPage.Name)



** Eseguo i vari requery se arrivo da pagine precedenti

If	cPageName = 'pgteste' And nOldPage < 4



	oPage.stdLabel1.Visible		= Thisform.Mode != 'EVADISINGLE'

	oPage.cmbTestata.Visible	= Thisform.Mode != 'EVADISINGLE'

	oPage.stdLabel2.Visible		= Thisform.Mode == 'EVADISINGLE'



	ThisForm.RequeryDOTes()

	oPage.cmbTestata.Requery()

	oPage.cmbTestata.ListIndex = 1



	If Thisform.Mode == 'EVADISINGLE'

		Replace Selected With .F. In DoTes All

		Locate

	EndIf 

EndIf



If	cPageName = 'pgselteste'	

	ThisForm.PF.pgSelTeste.cnt.cntGruppoCF			 .Visible = !InList(ThisForm.Mode, 'EVADI', 'EVADISINGLE')

	ThisForm.PF.pgSelTeste.cnt.cntClasseCF			 .Visible = !InList(ThisForm.Mode, 'EVADI', 'EVADISINGLE')

	ThisForm.PF.pgSelTeste.cnt.txtAreaCF  			 .Visible = !InList(ThisForm.Mode, 'EVADI', 'EVADISINGLE')

	ThisForm.PF.pgSelTeste.cnt.Extrainfo_flt1  	 .Visible = !InList(ThisForm.Mode, 'EVADI', 'EVADISINGLE')

EndIf



If	cPageName = 'pgrighe' And nOldPage < 7

	ThisForm.RequeryDORig()

EndIf



If	cPageName = 'pginsrighe'

	Select DoRig

	Zap

	Append Blank

	oPage.Grid.SetFocus()

EndIf



If nOldPage = 2 And InList(Thisform.Mode, 'EVADI', 'EVADISINGLE')

	This.pgselTeste.cnt.txtdataDoc.Field.wcSetMode(6)	&& <=

	This.pgselTeste.cnt.txtdataDoc.Field.Value = This.pgDocumento.txtDataDocumento.Field.Value

EndIf 



DoDefault(oPage,nOldPage,lJustRefreshed)





ENDPROC


*======================================================================

*** CLASS / OBJECT: LV (BaseClass: container, Parent: cmd.PF.pgGenerale) ***
*** PROPERTIES ***
Comment = "36142F6D-D30B-4099-9596-DA088C980A12"

Anchor = 5

Top = 4

Left = 0

Width = 100

Height = 420

ZOrderSet = 2

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

This.BackColor = oApp.ColorBtnShadow

DoDefault()



ENDPROC

PROCEDURE itemclick

LParameters oItem



Local cText



DoDefault(oItem)

With ThisForm

	.Mode = AllTrim(oItem.Key)



	.PF.pgSelTeste				.Enabled = (.Mode != 'CREA')

	.PF.pgTeste					.Enabled	= (.Mode != 'CREA')

	.PF.pgSelRighe				.Enabled = (.Mode != 'CREA') 								And .PF.pgDocumento.opgSelezioneAvanzataRighe.Value = 1

	.PF.PgSelRigheAvanzata	.Enabled = (InList(.Mode, 'EVADI', 'EVADISINGLE')) And .PF.pgDocumento.opgSelezioneAvanzataRighe.Value = 2

	.PF.pgRighe					.Enabled	= (.Mode != 'CREA')



	.PF.pgInsRighe.Enabled = (.Mode == 'CREA')

	

	Do Case

		Case .Mode == 'EVADI'

			cText = [Il documento verrà creato evadendo le righe dei documenti che successivamente verranno indicati]

			This.Parent.lblDescrizione.Caption				= cText

			.PF.pgSelTeste.Cnt.txtCd_CF.Field.wcSetmode(1)

			.PF.pgSelTeste.cnt.txtCd_CF.Field.Enabled		= .F.

			

			.PF.pgDocumento.chkDataConsegna.Visible = .T. 						



		Case .Mode == 'EVADISINGLE'

			cText = [Il documento verrà creato evadendo le righe del documento che successivamente verrà indicato]

			This.Parent.lblDescrizione.Caption				= cText

			.PF.pgSelTeste.Cnt.txtCd_CF.Field.wcSetmode(1)

			.PF.pgSelTeste.cnt.txtCd_CF.Field.Enabled		= .F.



			.PF.pgDocumento.chkDataConsegna.Visible = .T. 



		Case .Mode == 'COPIA'

			cText = [Il documento verrà creato copiando le righe dei documenti che successivamente verranno indicati]

			This.Parent.lblDescrizione.Caption				= cText			

			.PF.pgSelTeste.cnt.txtCd_CF.Field.Enabled		= .T.

			.PF.pgDocumento.opgSelezioneAvanzataRighe.SetValue(1)



			.PF.pgDocumento.chkDataConsegna.Visible = .T. 



		Case .Mode == 'CREA'

			cText = [Il documento verrà creato senza alcun prelievo o copia di documenti esistenti]

			This.Parent.lblDescrizione.Caption				= cText					



			.PF.pgDocumento.chkDataConsegna.Visible = .F. 



	EndCase



	.PF.pgDocumento.lblDoc.Visible					= (InList(.Mode, 'EVADI', 'EVADISINGLE'))

	.PF.pgDocumento.lstDoc.Visible					= (InList(.Mode, 'EVADI', 'EVADISINGLE'))	

	.PF.pgDocumento.chkMatricole.Visible			= (.Mode == 'COPIA')

	.PF.pgDocumento.chkPacking.Visible				= (.Mode == 'COPIA')

	.PF.pgDocumento.chkDistinte.Visible				= (.Mode == 'COPIA')

	.PF.pgDocumento.chkPrelevaRigheRif.Visible	= (InList(.Mode, 'EVADI', 'EVADISINGLE'))

	.PF.pgDocumento.Title_Label2.Visible			= (InList(.Mode, 'EVADI', 'EVADISINGLE'))

	

	.PF.pgDocumento.TitleLabel.Visible						= (.Mode != 'CREA')

	.PF.pgDocumento.chkSelTeste.Visible						= (.Mode != 'CREA')

	.PF.pgDocumento.chkSelezioneAvanzataRighe.Visible	= (.Mode != 'CREA')

	.PF.pgDocumento.opgSelezioneAvanzataRighe.Visible	= (InList(.Mode, 'EVADI', 'EVADISINGLE'))

	

	If .PF.pgDocumento.cmbCd_DO.ListCount > 0

		.PF.pgDocumento.cmbCd_DO.OnValueChange()

	EndIf



EndWith



ENDPROC


*======================================================================

*** CLASS / OBJECT: field (BaseClass: textbox, Parent: cmd.PF.pgDocumento.txtCd_CF) ***
*** PROPERTIES ***
ControlSource = ""

Top = 11

Width = 51

fktabledesc = Anagrafica

wcoperator = 1

fkalias = CF

fkhasdisplay = .T.

checkfor = 1

Name = "field"


*** METHODS ***
PROCEDURE isvalid

Lparameters lIsChanged, xOldValue



If lIsChanged

	ThisForm.lCFValidated = .F.

EndIf



If !ThisForm.lCFValidated

	ThisForm.lCFValidated = DoDefault(lIsChanged, xOldValue)

Endif



Return ThisForm.lCFValidated



ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



This.Parent.Parent.txtCd_VL.Field.SetValue(This.FkRecord.Cd_VL)

This.Parent.Parent.txtCd_VL.Field1.SetValue(GetFixing(This.FkRecord.Cd_VL, This.Parent.Parent.txtDataDocumento.Field.Value))



Thisform.PF.pgSelTeste.Cnt.txtCd_CF.Field.AnagraficheObsolete = This.AnagraficheObsolete

Thisform.PF.pgSelTeste.Cnt.txtCd_CF.Field.SetValue(This.Value)



**

This.Parent.Parent.lblAlert.Caption = Iif(This.FkRecord.EntePubblico, TB_(, "DBA16B86-EAC5-49A5-A0BD-79E1550A78E7", " !! Cliente privo di Codice Ufficio !! "),	;

																	 			 			 TB_(, "5C397C54-9CBD-4017-BBFA-59E5C351200F", " !! Cliente privo di Codice Destinatario / PEC B2B !! "))

																 	 

This.Parent.Parent.lblAlert.Visible = 	oApp.LicInfo.FatturaElettronica And ;

													InList(Left(This.FkRecord.Cd_CF, 1), 'C', 'P') And ;

													((This.FkRecord.EntePubblico And IsEmpty(This.FkRecord.CodiceIPA)) Or (!This.FkRecord.EntePubblico And IsEmpty(This.FkRecord.CodiceFPR)))





ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: cmd.PF.pgDocumento.txtCd_VL) ***
*** PROPERTIES ***
Format = "!"

Top = 11

Width = 45

fkselect = SELECT * FROM VL WHERE Cd_VL = <TEXT>

fktabledesc = Valute

fkalias = _VL_

fkdecodedfield = Descrizione

fkhasdisplay = .T.

required = .T.

Name = "Field"


*** METHODS ***
PROCEDURE wcgetwhere

LParameters cColumnName, lWc4XQuery



Return ' And DoTes.Cd_VL = ' + FormatC4Spt(This.Value)

ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



Thisform.PF.pgSelteste.cnt.txtCd_VL.Field.SetValue(This.Value)



This.Parent.Field1.Enabled  = This.Value != 'EUR'

This.Parent.Display.Visible = This.Value != 'EUR'



If This.Value == 'EUR'

	This.Parent.Field1.SetValue(1.0)

Else

	Local oRec, dDataRif, oDoRec



	dDataRif = This.Parent.Parent.txtDataDocumento.Field.Value

	oDoRec   = xSqlExec2Var('Select * From DO Where Cd_Do = ' + FormatC4Spt(This.Parent.Parent.cmbCd_DO.Value))



	oRec = GetFixing_2Obj(This.Value, dDataRif)



	If IsNull(oRec.Cambio)

		xMessageBox(Thisform.TB_(,'7A48B77F-68D6-43F1-9B59-829A229382D5', "Nessun cambio valido al %1! per %2!.", DToC(dDataRif), This.Value), MB_OK + MB_ICONSTOP)

		This.Parent.Field1.SetValue(1.0)

	Else

		This.Parent.Field1.SetValue(oRec.Cambio)



		If !SafeCompare(TToD(oRec.DataCambio), dDataRif) And !oRec.IsEuro

			xMessageBox(Thisform.TB_(,'4D321D79-390F-4E34-A212-F1C6480DD310', "Il cambio proposto per %1! risale al %2!", This.Value, DToC(oRec.DataCambio)), MB_OK + MB_ICONINFORMATION)

		EndIf

	EndIf

EndIf 





ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: cmd.PF.pgDocumento.txtDataDocumento) ***
*** PROPERTIES ***
Comment = "45EEF032-9CC4-4305-95A4-59DA86AC2476"

ControlSource = ""

Top = 11

Width = 63

Name = "Field"


*** METHODS ***
PROCEDURE onvaluechange

LParameters xOldValue



Local oRec, oTxtVL

Local dDataRif 



oTxtVL = This.Parent.Parent.txtCd_VL.Field



If oTxtVL.Value != 'EUR'



	dDataRif = This.Value



	oRec = GetFixing_2Obj(oTxtVL.Value, dDataRif)



	If IsNull(oRec.Cambio)

		xMessageBox(Thisform.TB_(,'7A48B77F-68D6-43F1-9B59-829A229382D5', "Nessun cambio valido al %1! per %2!.", DToC(dDataRif), oTxtVL.Value), MB_OK + MB_ICONSTOP)

		oTxtVL.Parent.Field1.SetValue(1.0)

	Else

		oTxtVL.Parent.Field1.SetValue(oRec.Cambio)



		If !SafeCompare(TToD(oRec.DataCambio), dDataRif) And !oRec.IsEuro

			xMessageBox(Thisform.TB_(,'4D321D79-390F-4E34-A212-F1C6480DD310', "Il cambio proposto per %1! risale al %2!", oTxtVL.Value, DToC(oRec.DataCambio)), MB_OK + MB_ICONINFORMATION)

		EndIf

	EndIf

EndIf 

ENDPROC

PROCEDURE Init

** Licenze a tempo

Local dDate

dDate = Date()

oApp.LicInfo.TestExpireDate(@dDate)

This.Value = dDate



Return DoDefault()

ENDPROC

PROCEDURE isvalid

LParameters lIsChanged, xOldValue



** Licenze a tempo

If !oApp.LicInfo.TestExpireDate(This.Value)

	Return .F.

EndIf 



Return DoDefault(lIsChanged, xOldValue)

ENDPROC


*======================================================================

*** CLASS / OBJECT: Field (BaseClass: combobox, Parent: cmd.PF.pgSelRighe.cmbTipoSpesa) ***
*** PROPERTIES ***
Comment = "A8FF0550-C006-443B-A265-59199D10A821"

Height = 20

Left = 87

Top = 0

Width = 100

wccolumnname = DORigSpesa.TipoRigaSpesa

Name = "Field"


*** METHODS ***
PROCEDURE Init

With This

	.AddItem('Tutte')

	.List(.ListCount, 2) = ' '

Endwith



Return DoDefault()



ENDPROC

PROCEDURE wcgetwhere

Lparameters cColumnName



If Empty(This.Value)

	Return ''

Else

	Return DoDefault(cColumnName)

Endif



ENDPROC


*======================================================================

*** CLASS / OBJECT: Field1 (BaseClass: textbox, Parent: cmd.PF.pgDocumento.txtCd_VL) ***
*** PROPERTIES ***
InputMask = "####.######"

Left = 47

Top = 11

required = .T.

Name = "Field1"


*** METHODS ***
PROCEDURE fkgetdata

Return This.Parent.Parent.txtDataDocumento.Field.Value 

ENDPROC

PROCEDURE fkgetvl

Return This.Parent.Field.Value 

ENDPROC


*======================================================================

*** CLASS / OBJECT: cmbCd_DO (BaseClass: combobox, Parent: cmd.PF.pgDocumento) ***
*** PROPERTIES ***
Comment = "687300E8-EB10-4577-B7E3-15CA7C8E339F"

Anchor = 10

Height = 20

Left = 10

TabIndex = 2

Top = 18

Width = 280

fkselectwhere = FTE_Autotipo=0

Name = "cmbCd_DO"


*** METHODS ***
PROCEDURE fkselect_access

Local cFKSelectWhere



cFKSelectWhere = This.FKSelectWhere



If This.DoBitMask != TD_TUTTO

	cFKSelectWhere =  cFKSelectWhere + ;

							Iif(Empty(cFKSelectWhere), '', ' And ') + ;

							'(dbo.afn_DoTypeAsMask(Do.TipoDocumento, Do.CliFor) & ' + ToHex(This.DoBitMask) + ' != 0)'

EndIf



Return 'Select * From Do Where Do.Cd_Do = <TEXT> And Do.Cd_ParcT Is Null' + Iif(Empty(cFKSelectWhere), '', ' And ' + cFKSelectWhere)+ ;

			oApp.oUser.GetDOWhere('Do.Cd_Do') && Alla fine aggiungo il filtro per i soli documenti visibili all'utente corrente. 





ENDPROC

PROCEDURE onvaluechange

LParameters xOldValue



Local lUseMG_P, lUseMG_A



ThisForm.WCDocFilter = ''



If !Empty(This.Value)

	Do Case

		Case InList(Thisform.Mode, 'EVADI', 'EVADISINGLE')

			ThisForm.QueryDoMgCausale(' And       DO.Cd_DO = ' + Format4Spt(This.Value))			

			Thisform.QueryDoDoPrel   (' And DODOPrel.Cd_DO = ' + Format4Spt(This.Value))

			Thisform.CheckAllRifExp()

			

		Case (Thisform.Mode == 'COPIA')

			ThisForm.QueryDoMgCausale(' And       DO.Cd_DO = ' + Format4Spt(This.Value))						

			Thisform.QueryDoDoPrel   (' And 1=0')

			

		Otherwise

			ThisForm.QueryDoMgCausale(' And       DO.Cd_DO = ' + Format4Spt(This.Value))						

			Thisform.QueryDoDoPrel   (' And 1=0')

			Thisform.PF.pgInsRighe.Grid.ColCd_AR.spcAR1.CheckFor = Iif(Eval(This.FKAlias + '.CliFor') = 'C', 1, 2)

	EndCase

	

	** Lista tipi documento prelevabili	

	This.Parent.lstDoc.Clear()

	Select DODOPrel

	Scan

		This.Parent.lstDoc.AddItem(DODOPrel.Cd_DO_Prelevabile)

		This.Parent.lstDoc.ListItem(This.Parent.lstDoc.ListCount, 2) 	= DODOPrel.Descrizione

		This.Parent.lstDoc.ListItem(This.Parent.lstDoc.ListCount, 3) 	= Tran(DODOPrel.PrelevaRif) + Tran(DODOPrel.GeneraRif) + Tran(DODOPrel.RifExp)

		This.Parent.lstDoc.SelectedChkID(This.Parent.lstDoc.ListCount) = .T.

	EndScan



	Use In DODOPrel



	** Impostazioni magazzini

	This.Parent.Cnt_MG.txtCd_MG_P.SetControl(xScatter('DoMgCausale'))

	This.Parent.Cnt_MG.txtCd_MG_A.SetControl(xScatter('DoMgCausale'))



	This.Parent.chkEsecutivo.Value		 = Eval(This.FKAlias + '.Esecutivo'       )

	This.Parent.chkPrelevabile.Value		 = Eval(This.FKAlias + '.Prelevabile'     )

	This.Parent.chkModificabile.Value	 = Eval(This.FKAlias + '.Modificabile'    )		

	This.Parent.chkPrelevaRigheRif.Value = Eval(This.FKAlias + '.UIRigaRifPreleva')



	** DOCIVATI

	If Eval(This.FKAlias + '.ImportiIvati')

		This.Parent.txtCd_VL.Field.Enabled =  .F.

		This.Parent.txtCd_VL.Field.SetValue('EUR')

		

		Thisform.PF.pgRighe.Grid.colPrezzoUnitarioV.Header1.Caption = Thisform.TB_(, "C2DAB8D8-29B6-4093-B617-ECAAEAD42F7E", 'Prezzo Un. Ivato')  

	Else

		This.Parent.txtCd_VL.Field.Enabled =  .T.	



		Thisform.PF.pgRighe.Grid.colPrezzoUnitarioV.Header1.Caption = Thisform.TB_(, "D591684E-8C6D-49EB-B951-F43197BA5191", 'Prezzo Un.')  

	EndIf 



EndIf



If Eval(This.FKAlias + '.TipoDocumento') = 'P'

	This.Parent.txtCd_CF.Field.FKMode   = Iif(Eval(This.FKAlias + '.CliFor') = 'C', 5, 6)	&& per i Preventivi faccio scegliere anche i Prospect

Else

	This.Parent.txtCd_CF.Field.FKMode   = Iif(Eval(This.FKAlias + '.CliFor') = 'C', 1, 2)

EndIf 



Do Case

	Case InList(Thisform.Mode, 'EVADI', 'EVADISINGLE')

		Thisform.PF.PgSelTeste.cnt.txtCD_DO.Field.FkSelectWhere  = "Cd_DO In (" + Evl(ThisForm.GetDocPreList(), "''") + ")"

		Thisform.PF.pgSelTeste.cnt.txtCd_CF.Field.FKMode 			= This.Parent.txtCd_CF.Field.FKMode		&& imposto lo stesso FKMode del campo di selezione del Cd_CF intestatario del documento



	Case Thisform.Mode == 'COPIA'

		Thisform.PF.PgSelTeste.cnt.txtCD_DO.Field.FkSelectWhere  = ""

		Thisform.PF.pgSelTeste.cnt.txtCd_CF.Field.FKMode 			= Iif(Eval(This.FKAlias + '.TipoDocumento') = 'P', 7, 0)		&& in caso di Preventivo imposto FKMode per vedere C/F/P/S, altrimenti solo C/F



	Otherwise

		Thisform.PF.PgSelTeste.cnt.txtCD_DO.Field.FkSelectWhere  = ""

		Thisform.PF.pgSelTeste.cnt.txtCd_CF.Field.FKMode 			= Iif(Eval(This.FKAlias + '.TipoDocumento') = 'P', 7, 0)		&& in caso di Preventivo imposto FKMode per vedere C/F/P/S, altrimenti solo C/F

EndCase 



ENDPROC


*======================================================================

*** CLASS / OBJECT: lblDoc (BaseClass: label, Parent: cmd.PF.pgDocumento) ***
*** PROPERTIES ***
Comment = "6ED41157-AA1D-436E-B10C-86E0DBA3977E"

Caption = " Tipi Documento da Evadere"

Height = 19

Left = 10

Top = 97

Width = 280

TabIndex = 10

Name = "lblDoc"


*** METHODS ***
PROCEDURE Click

THIS.PARENT.CLICK()

ENDPROC


*======================================================================

*** CLASS / OBJECT: Chkpacking (BaseClass: checkbox, Parent: cmd.PF.pgDocumento) ***
*** PROPERTIES ***
Comment = "EC7F82F4-5355-40FE-AE06-5F3FBCCF5C02"

Top = 164

Left = 33

Alignment = 0

Caption = "Copia Packing List"

Value = .T.

TabIndex = 13

Name = "Chkpacking"


*** METHODS ***
PROCEDURE Init

This.Top  = This.Parent.lblDoc.Top + 17

This.Left = This.Parent.lblDoc.Left

DoDefault()







ENDPROC


*======================================================================

*** CLASS / OBJECT: chkMatricole (BaseClass: checkbox, Parent: cmd.PF.pgDocumento) ***
*** PROPERTIES ***
Comment = "B86B2AF1-9EF4-400F-B893-0004C3EB4E42"

Top = 147

Left = 33

Alignment = 0

Caption = "Copia Righe Matricole"

Value = .F.

TabIndex = 12

Name = "chkMatricole"


*** METHODS ***
PROCEDURE Init

This.Top  = This.Parent.lblDoc.Top

This.Left = This.Parent.lblDoc.Left

DoDefault()







ENDPROC


*======================================================================

*** CLASS / OBJECT: chkEsecutivo (BaseClass: checkbox, Parent: cmd.PF.pgDocumento) ***
*** PROPERTIES ***
Comment = "B00D487F-8C45-4DEF-8ADA-EBAD4FC91A21"

Top = 22

Left = 384

Anchor = 8

Alignment = 0

Caption = "Esecutivo"

Value = .T.

TabIndex = 5

Name = "chkEsecutivo"


*** METHODS ***
PROCEDURE onrefresh

LParameters xOldValue



This.Parent.chkPrelevabile.Enabled = This.Value



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

*** CLASS / OBJECT: chkPrelevabile (BaseClass: checkbox, Parent: cmd.PF.pgDocumento) ***
*** PROPERTIES ***
Comment = "7B05164D-A5E7-4F9F-8548-447A41D64420"

Top = 22

Left = 451

Anchor = 8

Alignment = 0

Caption = "Prelevabile"

Value = .T.

TabIndex = 6

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

*** CLASS / OBJECT: chkModificabile (BaseClass: checkbox, Parent: cmd.PF.pgDocumento) ***
*** PROPERTIES ***
Comment = "B8E2B050-2050-4D38-97E2-2882502EBC61"

Top = 22

Left = 524

Anchor = 8

Alignment = 0

Caption = "Modificabile"

Value = .T.

TabIndex = 7

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

*** CLASS / OBJECT: chkDistinte (BaseClass: checkbox, Parent: cmd.PF.pgDocumento) ***
*** PROPERTIES ***
Comment = "C306BB56-0451-4447-A096-B32C328341CD"

Top = 181

Left = 33

Alignment = 0

Caption = "Copia Distinte Base"

Value = .T.

TabIndex = 14

Name = "chkDistinte"


*** METHODS ***
PROCEDURE Init

This.Top  = This.Parent.lblDoc.Top + 34

This.Left = This.Parent.lblDoc.Left

DoDefault()







ENDPROC


*======================================================================

*** CLASS / OBJECT: chkSelTeste (BaseClass: checkbox, Parent: cmd.PF.pgDocumento) ***
*** PROPERTIES ***
Comment = "E555ABE7-C0C5-45ED-A4A0-9DEF25C0325B"

Top = 261

Left = 315

Anchor = 8

Alignment = 0

Caption = "Selezione Avanzate Teste"

Value = .T.

TabIndex = 19

Name = "chkSelTeste"


*** METHODS ***
PROCEDURE Destroy

Thisform.UserPrefSetProperty(This, UP_SCOPE_COMPUSER, 'Value', This.Value)

DODEFAULT()

ENDPROC

PROCEDURE Init



DODEFAULT()



This.Value = Thisform.UserPrefGetProperty(This, UP_SCOPE_USER, 'Value', .T.)





ENDPROC

PROCEDURE onvaluechange

Lparameters xOldValue



This.Parent.Parent.pgSelTeste.Enabled = This.Value



Thisform.StepEnabler()



ENDPROC


*======================================================================

*** CLASS / OBJECT: TitleLabel (BaseClass: label, Parent: cmd.PF.pgDocumento) ***
*** PROPERTIES ***
Comment = "DBD32AAC-86AD-4F07-B868-D1BADFC7B7D8"

Anchor = 8

Caption = " Opzioni"

Height = 19

Left = 314

Top = 236

Width = 280

TabIndex = 18

Name = "TitleLabel"


*** METHODS ***
PROCEDURE Click

THIS.PARENT.CLICK()

ENDPROC


*======================================================================

*** CLASS / OBJECT: chkSelezioneAvanzataRighe (BaseClass: checkbox, Parent: cmd.PF.pgDocumento) ***
*** PROPERTIES ***
Comment = "AA1EC310-D75C-4A3F-96C5-12BFB46C0E7C"

Top = 277

Left = 315

Anchor = 8

Alignment = 0

Caption = "Selezione Avanzata Righe"

Value = .T.

TabIndex = 20

Name = "chkSelezioneAvanzataRighe"


*** METHODS ***
PROCEDURE onvaluechange

Lparameters xOldValue



This.Parent.opgSelezioneAvanzataRighe.Enabled = This.Value



This.Parent.Parent.pgSelRighe			 .Enabled = This.Value And This.Parent.opgSelezioneAvanzataRighe.Value = 1

This.Parent.Parent.PgSelRigheAvanzata.Enabled = This.Value And This.Parent.opgSelezioneAvanzataRighe.Value = 2 And InList(Thisform.Mode, 'EVADI', 'EVADISINGLE')

Thisform.StepEnabler()



ENDPROC

PROCEDURE Init



DODEFAULT()

** UP_SCOPE_USER, UP_SCOPE_COMP, UP_SCOPE_COMPUSER

This.Value = Thisform.UserPrefGetProperty(This, UP_SCOPE_COMPUSER, 'Value', .T.)







ENDPROC


*======================================================================

*** CLASS / OBJECT: opgSelezioneAvanzataRighe (BaseClass: optiongroup, Parent: cmd.PF.pgDocumento) ***
*** PROPERTIES ***
Anchor = 8

BorderStyle = 0

Height = 37

Left = 461

Top = 273

Width = 96

Name = "opgSelezioneAvanzataRighe"

Option1.Caption = "Filtri"

Option1.Left = 4

Option1.Top = 4

Option1.Name = "Option1"

Option2.Caption = "Griglia articoli"

Option2.Left = 4

Option2.Top = 20

Option2.Name = "Option2"


*** METHODS ***
PROCEDURE onvaluechange

LPARAMETERS xOldValue



This.Parent.Parent.pgSelRighe			 .Enabled = This.Parent.opgSelezioneAvanzataRighe.Value = 1

This.Parent.Parent.PgSelRigheAvanzata.Enabled = This.Parent.opgSelezioneAvanzataRighe.Value = 2 And InList(Thisform.Mode, 'EVADI', 'EVADISINGLE')

Thisform.StepEnabler()



ENDPROC


*======================================================================

*** CLASS / OBJECT: lblAlert (BaseClass: label, Parent: cmd.PF.pgDocumento) ***
*** PROPERTIES ***
AutoSize = .T.

BackStyle = 1

Caption = " !! Cliente privo di Codice Destinatario !!  "

Left = 64

Top = 75

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

*** CLASS / OBJECT: Grid (BaseClass: grid, Parent: cmd.PF.pgTeste) ***
*** PROPERTIES ***
ColumnCount = 21

Comment = "8B12345D-11AF-4645-8B49-4B06AB752CE5"

Anchor = 15

Height = 367

Left = 3

Panel = 1

RecordSource = "DOTes"

RowHeight = 17

Top = 54

Width = 676

Name = "Grid"

Stdcolumn1.Comment = "B29B195A-3626-437A-A615-090608166D35"

Stdcolumn1.FontName = "Segoe UI"

Stdcolumn1.FontSize = 8

Stdcolumn1.ControlSource = "DOTes.Selected"

Stdcolumn1.Width = 20

Stdcolumn1.Sparse = .F.

Stdcolumn1.Name = "ColSelected"

Stdcolumn2.Comment = "B3124B14-EF55-42DD-A5AD-D8B6DC14CE92"

Stdcolumn2.FontName = "Segoe UI"

Stdcolumn2.FontSize = 8

Stdcolumn2.ControlSource = "DoTes.Cd_CF"

Stdcolumn2.Width = 42

Stdcolumn2.Name = "ColCd_CF"

Stdcolumn3.Comment = "8A674185-3A5D-4661-B3C9-EF1428C4DC12"

Stdcolumn3.FontName = "Segoe UI"

Stdcolumn3.FontSize = 8

Stdcolumn3.ControlSource = "DOTes.Cd_Do"

Stdcolumn3.Width = 28

Stdcolumn3.Name = "ColCd_DO"

Stdcolumn4.Comment = "19791494-57CE-47C8-B70C-31BB1D6C601A"

Stdcolumn4.FontName = "Courier New"

Stdcolumn4.FontSize = 8

Stdcolumn4.ColumnOrder = 4

Stdcolumn4.ControlSource = "DOTes.NumeroDoc"

Stdcolumn4.Width = 63

Stdcolumn4.Name = "ColNumeroDoc"

Stdcolumn5.Comment = "21EDF6A9-84DF-4120-813F-861330AB1FFD"

Stdcolumn5.FontName = "Segoe UI"

Stdcolumn5.FontSize = 8

Stdcolumn5.ColumnOrder = 5

Stdcolumn5.ControlSource = "TTOD(DOTes.DataDoc)"

Stdcolumn5.Width = 48

Stdcolumn5.Name = "ColDataDoc"

Stdcolumn6.Comment = "4F8E3A2E-45D2-4E23-8AAA-F05C05745C20"

Stdcolumn6.FontName = "Segoe UI"

Stdcolumn6.FontSize = 8

Stdcolumn6.ColumnOrder = 6

Stdcolumn6.ControlSource = "DOTes.Cd_DOSottoCommessa"

Stdcolumn6.Width = 81

Stdcolumn6.Name = "ColCd_DOSottoCommessa"

Stdcolumn7.Comment = "71204131-5AF0-4763-8AAE-1F2AF003635F"

Stdcolumn7.FontName = "Segoe UI"

Stdcolumn7.FontSize = 8

Stdcolumn7.ColumnOrder = 7

Stdcolumn7.ControlSource = "DOTes.Cd_PG"

Stdcolumn7.Width = 36

Stdcolumn7.Name = "ColCd_PG"

Stdcolumn8.Comment = "D60ED194-8CA5-4F0F-B65A-F6E25BCEFB00"

Stdcolumn8.FontName = "Segoe UI"

Stdcolumn8.FontSize = 8

Stdcolumn8.ColumnOrder = 10

Stdcolumn8.ControlSource = "DOTes.Cd_Agente_1"

Stdcolumn8.Width = 56

Stdcolumn8.Name = "ColCd_Agente_1"

Stdcolumn9.Comment = "9BE4AB7A-2312-49BF-B994-BAD2FC9E9B21"

Stdcolumn9.FontName = "Segoe UI"

Stdcolumn9.FontSize = 8

Stdcolumn9.ColumnOrder = 11

Stdcolumn9.ControlSource = "DOTes.Cd_Agente_2"

Stdcolumn9.Width = 56

Stdcolumn9.Name = "ColCd_Agente_2"

Stdcolumn10.Comment = "E403840C-2291-4B40-841F-E32E1EDCEFDD"

Stdcolumn10.FontName = "Segoe UI"

Stdcolumn10.FontSize = 8

Stdcolumn10.ColumnOrder = 16

Stdcolumn10.ControlSource = "DOTes.Cd_VL"

Stdcolumn10.Width = 42

Stdcolumn10.Name = "ColCd_VL"

Stdcolumn11.Comment = "780C70ED-AE66-43B9-BB12-5583AA9E0C18"

Stdcolumn11.FontName = "Segoe UI"

Stdcolumn11.FontSize = 8

Stdcolumn11.ColumnOrder = 12

Stdcolumn11.ControlSource = "DOTes.Cd_CFZona"

Stdcolumn11.Width = 28

Stdcolumn11.Name = "ColCd_CFZona"

Stdcolumn12.Comment = "909590A7-AC48-4A69-85A2-214627668DB6"

Stdcolumn12.FontName = "Segoe UI"

Stdcolumn12.FontSize = 8

Stdcolumn12.ColumnOrder = 13

Stdcolumn12.ControlSource = "DOTes.Cd_CFDest"

Stdcolumn12.Width = 59

Stdcolumn12.Name = "ColCd_CFDest"

Stdcolumn13.Comment = "5675914F-9B29-4BFD-9A1E-38E207122559"

Stdcolumn13.FontName = "Segoe UI"

Stdcolumn13.FontSize = 8

Stdcolumn13.ColumnOrder = 17

Stdcolumn13.ControlSource = "DOTes.NumeroDocRif"

Stdcolumn13.Width = 73

Stdcolumn13.Name = "ColNumeroDocRif"

Stdcolumn14.Comment = "E10403EF-1661-4903-A702-B9BC1008DF7B"

Stdcolumn14.FontName = "Segoe UI"

Stdcolumn14.FontSize = 8

Stdcolumn14.ColumnOrder = 18

Stdcolumn14.ControlSource = "TTOD(DOTes.DataDocRif)"

Stdcolumn14.Width = 59

Stdcolumn14.Name = "ColDataDocRif"

Stdcolumn15.Comment = "AC05C168-F7FF-4DC4-8644-58E59E070DD3"

Stdcolumn15.FontName = "Segoe UI"

Stdcolumn15.FontSize = 8

Stdcolumn15.ColumnOrder = 14

Stdcolumn15.ControlSource = "DOTes.Cd_CFSede"

Stdcolumn15.Width = 63

Stdcolumn15.Name = "ColCd_CFSEDE"

Stdcolumn16.Comment = "3D16DB4E-A13F-4A44-AE3B-B5E6C7AC6777"

Stdcolumn16.FontName = "Segoe UI"

Stdcolumn16.FontSize = 8

Stdcolumn16.ColumnOrder = 15

Stdcolumn16.ControlSource = "DOTES.ScontoCassa"

Stdcolumn16.Name = "ColScontoCassa"

Stdcolumn17.Comment = "6EB1506B-7F59-420A-AAEA-EEBBDF34453A"

Stdcolumn17.FontName = "Segoe UI"

Stdcolumn17.FontSize = 8

Stdcolumn17.ColumnOrder = 8

Stdcolumn17.ControlSource = "IIF(DOTes.UE, 'SI', '  ')"

Stdcolumn17.Width = 34

Stdcolumn17.Name = "ColUE"

Stdcolumn18.Comment = "1CDF94DF-545C-4D53-AA66-8008D5C79005"

Stdcolumn18.FontName = "Segoe UI"

Stdcolumn18.FontSize = 8

Stdcolumn18.ColumnOrder = 19

Stdcolumn18.ControlSource = "DOTES.AccontoPerc"

Stdcolumn18.Width = 60

Stdcolumn18.InputMask = "###.##%"

Stdcolumn18.Name = "ColAccontoPerc"

Stdcolumn19.Comment = "EB315604-CE5E-4611-9A24-618B2B554EEF"

Stdcolumn19.FontName = "Segoe UI"

Stdcolumn19.FontSize = 8

Stdcolumn19.ColumnOrder = 20

Stdcolumn19.ControlSource = "DOTES.AccontoFissoV"

Stdcolumn19.InputMask = "###,###,###.##"

Stdcolumn19.Name = "ColAcconto"

Stdcolumn20.FontName = "Segoe UI"

Stdcolumn20.FontSize = 8

Stdcolumn20.ColumnOrder = 9

Stdcolumn20.ControlSource = "DOTES.CD_ReverseCharge"

Stdcolumn20.Width = 50

Stdcolumn20.Name = "ColCD_ReverseCharge"

Stdcolumn21.FontName = "Segoe UI"

Stdcolumn21.FontSize = 8

Stdcolumn21.ControlSource = "DOTES.cd_cgconto_banca"

Stdcolumn21.Width = 97

Stdcolumn21.Name = "ColBancaSconto"


*** METHODS ***
PROCEDURE onfocus

LPARAMETERS lEnter



WITH THISFORM.TOOLBAR

	.BUTTONS('ROWSEL').ENABLED 	= lEnter

	.BUTTONS('ROWUNSEL').ENABLED	= lEnter

ENDWITH



ENDPROC

PROCEDURE oncolumnheaderclick

LPARAMETERS ocol

OnColClickMakeIndex(oCol)

ENDPROC

PROCEDURE Init



DODEFAULT()

WITH THIS

	.InitAutoSaveLayout()

	.SetAll('DynamicBackColor', 'THIS.DynamicBackColor()')

	.SetAll('ReadOnly', .T.)

	.ColSelected.ReadOnly = .F.

	

	.ColCd_Agente_1.DynamicForeColor = 'THIS.DynamicForeColor("Cd_Agente_1")'

	.ColCd_Agente_2.DynamicForeColor = 'THIS.DynamicForeColor("Cd_Agente_2")'

	.ColScontoCassa.DynamicForeColor = 'THIS.DynamicForeColor("ScontoCassa")'

	.ColAccontoPerc.DynamicForeColor = 'THIS.DynamicForeColor("AccontoPerc")'

	.ColAcconto.DynamicForeColor 		= 'THIS.DynamicForeColor("AccontoFissoV")'

	.ColCd_PG.DynamicForeColor = 'THIS.DynamicForeColor("Cd_PG")'

	.ColCd_CFSede.DynamicForeColor = 'THIS.DynamicForeColor("Cd_CFSEDE")'

	.ColCd_CFDest.DynamicForeColor = 'THIS.DynamicForeColor("Cd_CFDest")'

	.ColCd_CFZona.DynamicForeColor = 'THIS.DynamicForeColor("Cd_CFZona")'

	.ColCd_ReverseCharge.DynamicForeColor = 'THIS.DynamicForeColor("Cd_ReverseCharge")'

	.colBancaSconto.DynamicForeColor = 'THIS.DynamicForeColor("Cd_CGConto_Banca")'

	

ENDWITH



ENDPROC

PROCEDURE dynamicbackcolor

IF DOTes.Id_DoTes == _cmbDoTestata.Id_DOTES

	RETURN oApp.ColorGridBackGreen

ELSE

	RETURN IIF(DOTes.Selected, oApp.ColorInfoBK, oApp.ColorWindow)

ENDIF	

ENDPROC

PROCEDURE dynamicforecolor

LPARAMETERS cField



IF !EMPTY(cField)

	RETURN IIF(EVALUATE('NVL(DOTES.&cfield,"") == NVL(_cmbDoTestata.&cfield, "")'), oApp.colorWindowtext, oApp.ColorGridForeRed)

ELSE

	RETURN oApp.colorWindowtext

ENDIF

ENDPROC


*======================================================================

*** CLASS / OBJECT: Grid (BaseClass: grid, Parent: cmd.PF.pgSelRigheAvanzata.cntPrelievoQta) ***
*** PROPERTIES ***
ColumnCount = 5

Comment = "ED96F178-815C-4E7D-B198-DD7DCAC98DA9"

Anchor = 15

AllowAddNew = .T.

Height = 392

Left = 3

Panel = 1

RecordSource = "ARQta"

RowHeight = 17

ScrollBars = 2

Top = 2

Width = 677

Name = "Grid"

Stdcolumn1.Comment = "6E006323-2720-4767-82F2-C4B28AD7B407"

Stdcolumn1.FontName = "Segoe UI"

Stdcolumn1.FontSize = 8

Stdcolumn1.ControlSource = "ARQta.Cd_AR"

Stdcolumn1.Width = 62

Stdcolumn1.Name = "ColCd_AR"

Stdcolumn2.Comment = "C4F8CD9C-43E4-4AA1-8D99-5E382442E3D0"

Stdcolumn2.FontName = "Segoe UI"

Stdcolumn2.FontSize = 8

Stdcolumn2.ControlSource = "ARQta.Descrizione"

Stdcolumn2.Width = 342

Stdcolumn2.ReadOnly = .T.

Stdcolumn2.Name = "ColDescrizione"

Stdcolumn3.Comment = "96A65A02-6809-4F90-9CB7-0D98AAAEF144"

Stdcolumn3.FontName = "Segoe UI"

Stdcolumn3.FontSize = 8

Stdcolumn3.Alignment = 2

Stdcolumn3.ControlSource = "ARQta.Cd_ARMisura"

Stdcolumn3.Width = 19

Stdcolumn3.Name = "ColCd_ARMisura"

Stdcolumn4.Comment = "6514AC97-A631-45F4-B1E3-3218068E13F9"

Stdcolumn4.FontName = "Segoe UI"

Stdcolumn4.FontSize = 8

Stdcolumn4.ColumnOrder = 5

Stdcolumn4.ControlSource = "ARQta.Qta"

Stdcolumn4.Width = 62

Stdcolumn4.Name = "ColQta"

Stdcolumn5.Comment = "B23A1E9E-C865-48A5-A473-D4B14734DED7"

Stdcolumn5.FontName = "Segoe UI"

Stdcolumn5.FontSize = 8

Stdcolumn5.ColumnOrder = 4

Stdcolumn5.ControlSource = "ARQta.UMFatt"

Stdcolumn5.Width = 50

Stdcolumn5.InputMask = "#,###.##"

Stdcolumn5.Name = "ColUMFatt"


*** METHODS ***
PROCEDURE rowinit

Lparameters nFromWhom



Replace Qta with 1.0 In ARQta



Return DoDefault(nFromWhom)



ENDPROC

PROCEDURE onfocus

LPARAMETERS lEnter



WITH Thisform.ToolBar

	.Buttons('ROWADD').Enabled = lEnter And This.Enabled

	.Buttons('ROWDEL').Enabled = lEnter And This.Enabled

ENDWITH



ENDPROC

PROCEDURE oncolumnheaderclick

LPARAMETERS oCol



OnColClickMakeIndex(oCol)

ENDPROC

PROCEDURE Init

IF !DODEFAULT()

	RETURN .F.

ENDIF

WITH THIS

	.InitAutoSaveLayout()

ENDWITH

APPEND BLANK IN (THIS.RecordSource)



ENDPROC


*======================================================================

*** CLASS / OBJECT: Stdcheck1 (BaseClass: checkbox, Parent: cmd.PF.pgTeste.Grid.ColSelected) ***
*** PROPERTIES ***
Comment = "C65F7C32-3BD1-42D1-BCB1-68A81CEC2181"

Top = 51

Left = 7

FontSize = 8

Alignment = 0

Caption = ""

Name = "Stdcheck1"


*** METHODS ***
PROCEDURE onvaluechange

LParameters xOldValue



If Thisform.Mode = 'EVADISINGLE'



	If !IsEmpty(This.Value)

		Local nRec

		nRec = Recno('DOTES')

		Replace Selected With .F. All In DOTes 

		Go (nRec) In DoTes

		Replace Selected With .T. 		In DOTes 	

		TableUpdate(.T., .T., 'DOTES')

		

	 	This.Parent.Parent.Parent.cmbTestaTa.Value = Transform(DOTes.Id_DOTes)

	EndIf 



Else 



	Local lInvalidateHeader, nId_DoTes

	With This.Parent.Parent

		nId_DoTes = 0

		If !Empty(.Parent.cmbTestaTa.Value)

			nId_DoTes = Evaluate(.Parent.cmbTestaTa.Value)

		EndIf

		If (!Selected And Id_DoTES = nId_DoTes) Or nId_DoTes = 0

			lInvalidateHeader = .T.

		EndIf

		** Devo Aggiornare il record, altrimenti la requery della combo non se la piglia

		TableUpdate(1, .T., 'DOTES')

		.Parent.cmbTestaTa.Requery()

		If lInvalidateHeader

			.Parent.cmbTestaTa.ListIndex = 1

		Else

			.Parent.cmbTestaTa.Value = Transform(nId_DoTes)

		EndIf

		.Refresh()

	EndWith



EndIf 

ENDPROC


*======================================================================

*** CLASS / OBJECT: Stdcheck1 (BaseClass: checkbox, Parent: cmd.PF.pgRighe.grid.ColSelected) ***
*** PROPERTIES ***
Comment = "F28C901D-FB7F-461D-800A-A9F985A12B30"

Top = 63

Left = 7

FontSize = 8

Alignment = 0

Caption = ""

Enabled = .T.

Name = "Stdcheck1"


*** METHODS ***
PROCEDURE onvaluechange

LPARAMETERS xOldValue



THISFORM.OnRowSelChange(DORIG.Selected)



THIS.PARENT.PARENT.Refresh()





ENDPROC


*======================================================================

*** CLASS / OBJECT: Stdcheck1 (BaseClass: checkbox, Parent: cmd.PF.pgRighe.GridRigheSpesa.ColSelected) ***
*** PROPERTIES ***
Comment = "3E88F2A2-E0E0-40FA-A785-F9A1A9F2C34F"

Top = 63

Left = 7

FontSize = 8

Alignment = 0

Caption = ""

Enabled = .T.

Name = "Stdcheck1"


*** METHODS ***
PROCEDURE onvaluechange

LPARAMETERS xOldValue



THISFORM.onRowSpesaSelChange(xOldValue)



**	LOCAL oTxtImportoV



**	oTxtImportoV = This.Parent.Parent.ColImportoV.Text1



**	IF THIS.Value

**		** Sto selezionando, imposto 

**		oTxtImportoV.SetValue(DoRigSpesa.ImportoEvadibileV)

**	ELSE

**		** Sto deselezionando, azzero 

**		oTxtImportoV.SetValue(0)

**	ENDIF



THIS.PARENT.PARENT.REFRESH()

ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: cmd.PF.pgRighe.grid.ColCd_ARMisura) ***
*** PROPERTIES ***
FontSize = 8

BorderStyle = 0

Enabled = .T.

Margin = 0

Name = "Text1"


*** METHODS ***
PROCEDURE fkgetcodar

Return DoRig.Cd_AR

ENDPROC

PROCEDURE onvaluechange

LPARAMETERS xOldValue



LOCAL oRec

LOCAL nNewQta, nNewFatt



oRec = xSqlExec2Obj('SELECT Cd_ARMisura, UMFatt, DefaultMisura FROM ARARMisura WHERE Cd_AR = ' + Format4Spt(DoRig.Cd_AR) + ' AND Cd_ARMisura = ' + Format4Spt(DoRig.Cd_ARMisura))

nNewFatt = IIF(ISNULL(oRec), 1.0, oRec.UMFatt)



nNewQta = Qta * FattoreToUM1 / nNewFatt



REPLACE ;

	FattoreToUM1 		WITH nNewFatt, 									;

	PrezzoUnitarioV 	WITH PrezzoUnitarioV_UM * FattoreToUM1, ;

	Qta					WITH nNewQta 									;

	IN DoRig





**	THISFORM.OnRowQtachange()	 

**	THIS.Parent.Parent.Refresh()

ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: cmd.PF.pgRighe.grid.ColFattoreToUM1) ***
*** PROPERTIES ***
Comment = "5ED5C892-B95C-43E3-A927-B14CD8EB648D"

FontSize = 8

BorderStyle = 0

Enabled = .F.

Margin = 0

Name = "Text1"


*** METHODS ***
PROCEDURE onvaluechange

LPARAMETERS xOldValue



REPLACE ;

	PrezzoUnitarioV 	WITH PrezzoUnitarioV_UM * FattoreToUM1 ;

	IN DoRig



ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: cmd.PF.pgRighe.grid.ColQta) ***
*** PROPERTIES ***
Comment = "5078B32B-8357-414B-AE18-93C901842BD9"

FontSize = 8

BorderStyle = 0

Enabled = .T.

Margin = 0

Name = "Text1"


*** METHODS ***
PROCEDURE onvaluechange

LPARAMETERS xOldValue



THISFORM.OnRowQtaChange(.T.)





ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: cmd.PF.pgRighe.grid.ColCd_ARMisura_RE) ***
*** PROPERTIES ***
FontSize = 8

BorderStyle = 0

Enabled = .F.

Margin = 0

Name = "Text1"


*** METHODS ***
PROCEDURE fkgetcodar

Return DoRig.Cd_AR

ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: cmd.PF.pgRighe.grid.ColPrezzoUnitarioV) ***
*** PROPERTIES ***
Comment = "9CFFF160-109A-4304-8275-B57FE88E8F75"

FontSize = 8

BorderStyle = 0

Enabled = .F.

Margin = 0

Name = "Text1"


*** METHODS ***
PROCEDURE tooltiptext_access

IF DoRig.FattoreToUM1 = 1.0

	RETURN ''

ELSE

	RETURN IIF(LEFT(DoRig.Cd_CF, 1) == 'C', 'Prezzo','Costo') + ' in unità di misura principale: ' + TRAN(DoRig.PrezzoUnitarioV_UM)

ENDIF

ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: cmd.PF.pgRighe.GridRigheSpesa.ColImportoV) ***
*** PROPERTIES ***
Comment = "A64CF32C-EF64-42FA-BDCD-55005C6F443F"

FontSize = 8

BorderStyle = 0

Left = 32

Margin = 0

Top = 35

Name = "Text1"


*** METHODS ***
PROCEDURE onvaluechange

LPARAMETERS xOldValue



THISFORM.onRowSpesaImportoVChange()



	

ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: cmd.PF.pgInsRighe.grid.ColQta) ***
*** PROPERTIES ***
Comment = "D9508351-DE65-43A6-BB57-A9FAC7D1B5CA"

FontSize = 8

BorderStyle = 0

Enabled = .T.

Margin = 0

Name = "Text1"


*** METHODS ***
PROCEDURE onvaluechange

LPARAMETERS xOldValue



THISFORM.OnRowQtaChange(.T.)





ENDPROC


*======================================================================

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: cmd.PF.pgSelRigheAvanzata.cntPrelievoQta.Grid.ColDescrizione) ***
*** PROPERTIES ***
Comment = "9B073E42-78D0-4311-B679-B0EEFCF127B2"

FontSize = 8

BorderStyle = 0

Margin = 0

ReadOnly = .T.

Name = "Text1"


*** METHODS ***
PROCEDURE When

RETURN .F.

ENDPROC


*======================================================================

*** CLASS / OBJECT: cmbTestata (BaseClass: combobox, Parent: cmd.PF.pgTeste) ***
*** PROPERTIES ***
Comment = "7122B2F5-B764-46E7-910C-148D0775585D"

FontName = "Courier New"

BoundColumn = 2

RowSourceType = 3

RowSource = "Select Cd_DO + NumeroDoc + DTOC(TTOD(DataDoc)) AS  Doc,TRAN( id_dotes, '########'), * FROM DOTES WHERE Selected INTO CURSOR _cmbDOTestata ORDER BY DataDoc"

Height = 21

Left = 249

Top = 6

Width = 200

BoundTo = .T.

Name = "cmbTestata"


*** METHODS ***
PROCEDURE onvaluechange

LPARAMETERS xOldValue

THIS.Parent.Grid.Refresh()

ENDPROC

PROCEDURE Requery

LOCAL cValue

cValue = THIS.Value

DODEFAULT()

IF !EMPTY(cValue)

	THIS.Value = cValue

ELSE

	THIS.ListIndex = 1

ENDIF	

ENDPROC


*======================================================================

*** CLASS / OBJECT: cmbOrderBy (BaseClass: combobox, Parent: cmd.PF.pgTeste) ***
*** PROPERTIES ***
Comment = "CEDA3B76-65B7-4349-A41C-AA42FEAB88EC"

FontName = "Courier New"

ColumnCount = 1

Height = 21

Left = 249

Top = 29

Width = 200

Name = "cmbOrderBy"


*** METHODS ***
PROCEDURE Init

DoDefault()



** 1a colonna: Descrizione

** 2a colonna: OrderBy per cursori VFP

** 3a colonna: OrderBy per SQLStmt



This.AddItems('Data, Tipo Doc., Numero Doc.', 'Dtos(DataDoc) + Cd_DO + NumeroDoc+ Padl(Riga, 5, "0")', 'DORig.DataDoc, DORig.Cd_DO, DORig.NumeroDoc, DORig.Riga')

This.AddItems('Tipo Doc., Data, Numero Doc.', 'Cd_DO + Dtos(DataDoc) + NumeroDoc+ Padl(Riga, 5, "0")', 'DORig.Cd_DO, DORig.DataDoc, DORig.NumeroDoc, DORig.Riga')	

This.ListIndex = 1

ENDPROC


*======================================================================

*** CLASS / OBJECT: grid (BaseClass: grid, Parent: cmd.PF.pgRighe) ***
*** PROPERTIES ***
ColumnCount = 21

Comment = "B5E4C3DB-B0E9-4EC1-BAD9-FA238A7BEA51"

Anchor = 15

Height = 259

Left = 2

Panel = 1

RecordSource = "DORig"

RowHeight = 17

Top = 3

Width = 678

Name = "grid"

Stdcolumn1.Comment = "B70D7520-637E-4E10-80DD-F7330D55D07A"

Stdcolumn1.FontName = "Segoe UI"

Stdcolumn1.FontSize = 8

Stdcolumn1.ControlSource = "DORig.Selected"

Stdcolumn1.Width = 20

Stdcolumn1.Sparse = .F.

Stdcolumn1.Name = "ColSelected"

Stdcolumn2.Comment = "6FA4B4B4-5709-4DCF-B999-0224AF1A88AA"

Stdcolumn2.FontName = "Segoe UI"

Stdcolumn2.FontSize = 8

Stdcolumn2.ControlSource = "DoRig.Cd_CF"

Stdcolumn2.Enabled = .F.

Stdcolumn2.Width = 50

Stdcolumn2.Name = "ColCd_CF"

Stdcolumn3.Comment = "F83DE3ED-5F89-4ACA-8E9E-58D121D361C8"

Stdcolumn3.FontName = "Segoe UI"

Stdcolumn3.FontSize = 8

Stdcolumn3.ControlSource = "DoRig.Cd_DO"

Stdcolumn3.Enabled = .F.

Stdcolumn3.Width = 28

Stdcolumn3.Name = "ColCd_DO"

Stdcolumn4.Comment = "8EA71FBE-9F28-4D10-B25B-9127728AD099"

Stdcolumn4.FontName = "Courier New"

Stdcolumn4.FontSize = 8

Stdcolumn4.ColumnOrder = 4

Stdcolumn4.ControlSource = "DoRig.NumeroDoc"

Stdcolumn4.Enabled = .F.

Stdcolumn4.Width = 67

Stdcolumn4.Name = "ColNumeroDoc"

Stdcolumn5.Comment = "6E6E9501-4A5D-47DC-9A56-0D2B526A266E"

Stdcolumn5.FontName = "Segoe UI"

Stdcolumn5.FontSize = 8

Stdcolumn5.ColumnOrder = 5

Stdcolumn5.ControlSource = "DoRig.Cd_AR"

Stdcolumn5.Enabled = .F.

Stdcolumn5.Width = 78

Stdcolumn5.Name = "ColCd_AR"

Stdcolumn6.Comment = "A6E33F3D-4867-474E-8F63-25B808712CD2"

Stdcolumn6.FontName = "Segoe UI"

Stdcolumn6.FontSize = 8

Stdcolumn6.ColumnOrder = 7

Stdcolumn6.ControlSource = "DoRig.Descrizione"

Stdcolumn6.Enabled = .F.

Stdcolumn6.Width = 144

Stdcolumn6.Name = "ColDescrizione"

Stdcolumn7.Comment = "A99C6FF0-4EEC-4D37-BD3C-97C2653EDFAF"

Stdcolumn7.FontName = "Segoe UI"

Stdcolumn7.FontSize = 8

Stdcolumn7.ColumnOrder = 8

Stdcolumn7.ControlSource = "DoRig.Cd_ARMisura"

Stdcolumn7.Enabled = .T.

Stdcolumn7.Width = 19

Stdcolumn7.Name = "ColCd_ARMisura"

Stdcolumn8.Comment = "E6FD3AAF-AADA-4862-A891-87B1F896F98F"

Stdcolumn8.FontName = "Segoe UI"

Stdcolumn8.FontSize = 8

Stdcolumn8.ColumnOrder = 9

Stdcolumn8.ControlSource = "DoRig.FattoreToUM1"

Stdcolumn8.Enabled = .F.

Stdcolumn8.Width = 60

Stdcolumn8.InputMask = "###,###.#####"

Stdcolumn8.Name = "ColFattoreToUM1"

Stdcolumn9.Comment = "0C493C8C-CEA0-4EAC-9C4C-2E91A70A7BA1"

Stdcolumn9.FontName = "Segoe UI"

Stdcolumn9.FontSize = 8

Stdcolumn9.ColumnOrder = 10

Stdcolumn9.ControlSource = "DoRig.Qta"

Stdcolumn9.Enabled = .T.

Stdcolumn9.Width = 56

Stdcolumn9.Name = "ColQta"

Stdcolumn10.Comment = "156AB66A-5DBB-4683-AD53-396C529EEDF8"

Stdcolumn10.FontName = "Segoe UI"

Stdcolumn10.FontSize = 8

Stdcolumn10.ColumnOrder = 11

Stdcolumn10.ControlSource = "DoRig.Cd_ARMisura_RE"

Stdcolumn10.Enabled = .F.

Stdcolumn10.Width = 56

Stdcolumn10.Name = "ColCd_ARMisura_RE"

Stdcolumn11.Comment = "18C67D5A-A798-4AC5-800F-A76AD4C238EF"

Stdcolumn11.FontName = "Segoe UI"

Stdcolumn11.FontSize = 8

Stdcolumn11.ColumnOrder = 12

Stdcolumn11.ControlSource = "DoRig.FattoreToUM1_RE"

Stdcolumn11.Enabled = .F.

Stdcolumn11.Width = 60

Stdcolumn11.InputMask = "###,###.#####"

Stdcolumn11.Name = "ColFattoreToUM1_RE"

Stdcolumn12.Comment = "B97CF54B-E76F-4A23-9156-E4F3A27C7847"

Stdcolumn12.FontName = "Segoe UI"

Stdcolumn12.FontSize = 8

Stdcolumn12.ColumnOrder = 13

Stdcolumn12.ControlSource = "DoRig.QtaResidua"

Stdcolumn12.Enabled = .T.

Stdcolumn12.Width = 50

Stdcolumn12.Name = "ColQtaResidua"

Stdcolumn13.Comment = "452C80E3-291C-4806-A45C-C13CDA003480"

Stdcolumn13.FontName = "Segoe UI"

Stdcolumn13.FontSize = 8

Stdcolumn13.ColumnOrder = 14

Stdcolumn13.ControlSource = "DoRig.PrezzoUnitarioV"

Stdcolumn13.Enabled = .F.

Stdcolumn13.Width = 67

Stdcolumn13.Name = "ColPrezzoUnitarioV"

Stdcolumn14.Comment = "251413C4-EC8F-4B5C-8A1E-E5D6B7D119E2"

Stdcolumn14.FontName = "Segoe UI"

Stdcolumn14.FontSize = 8

Stdcolumn14.ColumnOrder = 16

Stdcolumn14.ControlSource = "DoRig.PrezzoTotaleV"

Stdcolumn14.Enabled = .F.

Stdcolumn14.Width = 73

Stdcolumn14.Name = "ColPrezzoTotaleV"

Stdcolumn15.Comment = "4DCB7CAE-3C36-42E2-90C4-D43B2395AFF7"

Stdcolumn15.FontName = "Segoe UI"

Stdcolumn15.FontSize = 8

Stdcolumn15.ColumnOrder = 17

Stdcolumn15.ControlSource = "DoRig.ScontoRiga"

Stdcolumn15.Enabled = .F.

Stdcolumn15.Width = 42

Stdcolumn15.Name = "ColScontoRiga"

Stdcolumn16.Comment = "CCCEA287-9A7B-47C5-A6EA-56DE46C9BEFF"

Stdcolumn16.FontName = "Segoe UI"

Stdcolumn16.FontSize = 8

Stdcolumn16.ColumnOrder = 20

Stdcolumn16.ControlSource = "TTOD(DoRig.DataConsegna)"

Stdcolumn16.Enabled = .F.

Stdcolumn16.Width = 67

Stdcolumn16.Name = "ColDataConsegna"

Stdcolumn17.Comment = "D32DA569-75A4-48A1-B3C5-2F685283F2C4"

Stdcolumn17.FontName = "Segoe UI"

Stdcolumn17.FontSize = 8

Stdcolumn17.ColumnOrder = 21

Stdcolumn17.ControlSource = "DoRig.Cd_ARLotto"

Stdcolumn17.Enabled = .F.

Stdcolumn17.Width = 36

Stdcolumn17.Name = "ColCd_ARLotto"

Stdcolumn18.Comment = "963AE38D-3444-46BA-A1BA-C7E737BDA059"

Stdcolumn18.FontName = "Segoe UI"

Stdcolumn18.FontSize = 8

Stdcolumn18.ColumnOrder = 18

Stdcolumn18.ControlSource = "DoRig.ProvvigioneRiga_1"

Stdcolumn18.Enabled = .F.

Stdcolumn18.Width = 56

Stdcolumn18.Name = "ColProvvigioneRiga_1"

Stdcolumn19.Comment = "25BB6CDA-1D98-4D59-BD29-777CA48D8723"

Stdcolumn19.FontName = "Segoe UI"

Stdcolumn19.FontSize = 8

Stdcolumn19.ColumnOrder = 19

Stdcolumn19.ControlSource = "DoRig.ProvvigioneRiga_2"

Stdcolumn19.Enabled = .F.

Stdcolumn19.Width = 56

Stdcolumn19.Name = "ColProvvigioneRiga_2"

Stdcolumn20.Comment = "AA90959F-F50D-403D-ABD1-8DC0FE57126D"

Stdcolumn20.FontName = "Segoe UI"

Stdcolumn20.FontSize = 8

Stdcolumn20.ColumnOrder = 15

Stdcolumn20.ControlSource = "DoRig.PrezzoAddizionaleV"

Stdcolumn20.Enabled = .F.

Stdcolumn20.Width = 94

Stdcolumn20.Name = "colPrezzoAddizionaleV"

Stdcolumn21.Comment = "23948709-B99F-49E4-A8BF-2D134CB526B3"

Stdcolumn21.FontName = "Segoe UI"

Stdcolumn21.FontSize = 8

Stdcolumn21.ColumnOrder = 6

Stdcolumn21.ControlSource = "DORig.DocEvaso_CodiceAlternativo"

Stdcolumn21.Enabled = .F.

Stdcolumn21.Width = 42

Stdcolumn21.Name = "ColCodiceAlternativo"


*** METHODS ***
PROCEDURE dynamicbackcolor

RETURN IIF(DORig.Selected, oApp.ColorInfoBK, oApp.ColorWindow)

ENDPROC

PROCEDURE oncolumnheaderclick

LPARAMETERS ocol

OnColClickMakeIndex(oCol)

ENDPROC

PROCEDURE Init

IF !DODEFAULT()

	RETURN .F.

ENDIF

WITH THIS

	.InitAutoSaveLayout()

	.SetAll('DynamicBackColor', 'THIS.DynamicBackColor()')

ENDWITH



ENDPROC

PROCEDURE onfocus

LPARAMETERS lEnter



WITH THISFORM.TOOLBAR

	.BUTTONS('ROWSEL').ENABLED 	= lEnter

	.BUTTONS('ROWUNSEL').ENABLED	= lEnter

ENDWITH



ENDPROC

PROCEDURE layoutset

Lparameters cLayoutInfo



** Non ci sono impostazioni per la colonna ColCodiceAlternativo: è la prima volta che viene aggiunta, la posiziono con un default 

DoDefault(cLayoutInfo)

If Atc('ColCodiceAlternativo', cLayoutInfo) = 0

 	This.SetColumnOrder(This.ColCodiceAlternativo,  6)

Endif

ENDPROC


*======================================================================

*** CLASS / OBJECT: grid (BaseClass: grid, Parent: cmd.PF.pgInsRighe) ***
*** PROPERTIES ***
ColumnCount = 3

Comment = "A5640878-BA89-450A-9D85-6332B5B3FB2F"

Anchor = 15

AllowAddNew = .T.

Height = 412

Left = 3

Panel = 1

RecordSource = "DORig"

RowHeight = 17

Top = 3

Width = 676

Name = "grid"

Stdcolumn1.Comment = "0E1D7690-730E-4164-8686-513D3986DE8B"

Stdcolumn1.FontName = "Segoe UI"

Stdcolumn1.FontSize = 8

Stdcolumn1.ControlSource = "DoRig.Cd_AR"

Stdcolumn1.Width = 78

Stdcolumn1.Name = "ColCd_AR"

Stdcolumn2.Comment = "D71FB421-D1B3-4E91-9749-36719051033C"

Stdcolumn2.FontName = "Segoe UI"

Stdcolumn2.FontSize = 8

Stdcolumn2.ControlSource = "DoRig.Descrizione"

Stdcolumn2.Enabled = .F.

Stdcolumn2.Width = 352

Stdcolumn2.Name = "ColDescrizione"

Stdcolumn3.Comment = "67891D0B-934E-4B3C-9D79-EDC6BC811A0C"

Stdcolumn3.FontName = "Segoe UI"

Stdcolumn3.FontSize = 8

Stdcolumn3.ControlSource = "DoRig.Qta"

Stdcolumn3.Width = 64

Stdcolumn3.Name = "ColQta"


*** METHODS ***
PROCEDURE Init

IF !DODEFAULT()

	RETURN .F.

ENDIF



WITH THIS

	.InitAutoSaveLayout()

ENDWITH



ENDPROC


*======================================================================

*** CLASS / OBJECT: Stdtext1 (BaseClass: textbox, Parent: cmd.PF.pgSelRigheAvanzata.cntPrelievoQta.Grid.ColCd_ARMisura) ***
*** PROPERTIES ***
FontSize = 8

Alignment = 2

BorderStyle = 0

Left = 16

Margin = 0

Top = 66

fktabledesc = Unitàdimisura

fkalias = ARQtaARMisura

Name = "Stdtext1"


*** METHODS ***
PROCEDURE fkgetcodar

Return ARQta.Cd_AR

ENDPROC

PROCEDURE onvaluechange

LPARAMETERS xOldValue



LOCAL oRec

LOCAL nNewQta, nNewFatt



oRec = xSqlExec2Obj('SELECT Cd_ARMisura, UMFatt, DefaultMisura FROM ARARMisura WHERE Cd_AR = ' + Format4Spt(ArQta.Cd_AR) + ' AND Cd_ARMisura = ' + Format4Spt(THIS.VALUE))

nNewFatt = IIF(ISNULL(oRec), 1.0, oRec.UMFatt)



nNewQta = Qta * UMFatt / nNewFatt



REPLACE ;

	UMFatt		WITH nNewFatt, ;

	Qta			WITH nNewQta ;

	IN ARQta

ENDPROC


*======================================================================

*** CLASS / OBJECT: GridRigheSpesa (BaseClass: grid, Parent: cmd.PF.pgRighe) ***
*** PROPERTIES ***
ColumnCount = 9

Comment = "091035A4-84B4-4397-B473-F5084467E316"

Anchor = 14

Height = 151

Left = 2

Panel = 1

RecordSource = "DORigSpesa"

Top = 266

Width = 678

Name = "GridRigheSpesa"

Stdcolumn1.Comment = "69509A41-B071-4184-B738-9C75464CC111"

Stdcolumn1.FontName = "Segoe UI"

Stdcolumn1.FontSize = 8

Stdcolumn1.ControlSource = "DORigSpesa.Selected"

Stdcolumn1.Width = 23

Stdcolumn1.Sparse = .F.

Stdcolumn1.Name = "ColSelected"

Stdcolumn2.Comment = "10E5D76D-0137-4E5E-97AB-AB7848E15E7F"

Stdcolumn2.FontName = "Segoe UI"

Stdcolumn2.FontSize = 8

Stdcolumn2.ControlSource = "DORigSpesa.Cd_CF"

Stdcolumn2.Enabled = .F.

Stdcolumn2.Width = 60

Stdcolumn2.Name = "ColCd_CF"

Stdcolumn3.Comment = "1A14657D-1C7F-4CBC-B94B-F94C2439F983"

Stdcolumn3.FontName = "Segoe UI"

Stdcolumn3.FontSize = 8

Stdcolumn3.ControlSource = "DORigSpesa.Cd_DO"

Stdcolumn3.Enabled = .F.

Stdcolumn3.Width = 36

Stdcolumn3.Name = "ColCd_DO"

Stdcolumn4.Comment = "45185C05-D58E-4121-9641-9D14797993B4"

Stdcolumn4.FontName = "Courier New"

Stdcolumn4.FontSize = 8

Stdcolumn4.ControlSource = "DORigSpesa.NumeroDoc"

Stdcolumn4.Enabled = .F.

Stdcolumn4.Width = 79

Stdcolumn4.Name = "ColNumeroDoc"

Stdcolumn5.Comment = "7568CE63-5022-4545-B57D-C344638E6C3F"

Stdcolumn5.FontName = "Segoe UI"

Stdcolumn5.FontSize = 8

Stdcolumn5.ControlSource = "Decode_TipoSpesa(DoRigSpesa.TipoRigaSpesa)"

Stdcolumn5.Enabled = .F.

Stdcolumn5.Width = 60

Stdcolumn5.Name = "ColTipoRIgaSpesa"

Stdcolumn6.Comment = "17E6C05B-2720-4FBF-AFA4-317DE68D219F"

Stdcolumn6.FontName = "Segoe UI"

Stdcolumn6.FontSize = 8

Stdcolumn6.ControlSource = "DoRigSpesa.Descrizione"

Stdcolumn6.Width = 163

Stdcolumn6.Name = "ColDescrizione"

Stdcolumn7.Comment = "B7FA1BEA-115F-4049-951F-DBD3EA3052AA"

Stdcolumn7.FontName = "Segoe UI"

Stdcolumn7.FontSize = 8

Stdcolumn7.ControlSource = "DORigSpesa.ImportoEvadibileV"

Stdcolumn7.Enabled = .F.

Stdcolumn7.Width = 87

Stdcolumn7.Name = "ColImportoEvadibileV"

Stdcolumn8.Comment = "CCB15282-B6A0-4AD8-8FB8-A9CF7AE52A14"

Stdcolumn8.FontName = "Segoe UI"

Stdcolumn8.FontSize = 8

Stdcolumn8.ControlSource = "DORigSpesa.ImportoV"

Stdcolumn8.Width = 60

Stdcolumn8.Name = "ColImportoV"

Stdcolumn9.Comment = "BC8E3A3A-5950-42B7-8588-327A97787E79"

Stdcolumn9.FontName = "Segoe UI"

Stdcolumn9.FontSize = 8

Stdcolumn9.ControlSource = "DORigSpesa.ImportoResiduoV"

Stdcolumn9.Width = 110

Stdcolumn9.Name = "ColImportoResiduoV"


*** METHODS ***
PROCEDURE Init

IF !DODEFAULT()

	RETURN .F.

ENDIF

WITH THIS

	.InitAutoSaveLayout()

	.SetAll('DynamicBackColor', 'THIS.DynamicBackColor()')

ENDWITH



ENDPROC

PROCEDURE oncolumnheaderclick

LPARAMETERS ocol

OnColClickMakeIndex(oCol)

ENDPROC

PROCEDURE dynamicbackcolor

RETURN IIF(DORigSpesa.Selected, oApp.ColorInfoBK, oApp.ColorWindow)

ENDPROC

PROCEDURE onfocus

LPARAMETERS lEnter



WITH THISFORM.TOOLBAR

	.BUTTONS('ROWSEL').ENABLED 	= lEnter

	.BUTTONS('ROWUNSEL').ENABLED	= lEnter

ENDWITH



ENDPROC


*======================================================================

*** CLASS / OBJECT: Spcar1 (BaseClass: textbox, Parent: cmd.PF.pgInsRighe.grid.ColCd_AR) ***
*** PROPERTIES ***
FontSize = 8

BorderStyle = 0

Left = 55

Margin = 0

Top = 107

fkalias = _ar_

Name = "Spcar1"


*** METHODS ***
PROCEDURE onvaluechange

LParameters xOldValue



Local oRec, cCd_DO, cCd_CF



cCd_DO = Thisform.PF.pgDocumento.cmbCd_DO.Value

cCd_CF = Thisform.PF.pgDocumento.txtCd_CF.Field.Value



oRec = DoRig_Defaults_UM_2Obj(cCd_DO, cCd_CF, Null, This.Value) 



Replace ;

	Descrizione  		With Evaluate(This.FKAlias + '.Descrizione'), ;

	Cd_ARMisura  		With oRec.Cd_ARMisura, ;

	FattoreToUM1 		With oRec.FattoreToUM1, ;

	FattoreToUM1_RE 	With oRec.FattoreToUM1 ;

	In DORig



Select DORig

Scatter Memo Name oRec

Thisform.NormMagazzini(oRec)

Gather Memo Name oRec



** Se ho appena digitato il codice articolo, e quindi la Qtà è zero, la imposto ad 1 ed eseguo il controllo giacenza se richiesto.

If IsEmpty(DORig.Qta)

	Replace Qta	With 1

	Thisform.OnRowQtaChange(.T.)

EndIf 



ENDPROC

PROCEDURE fkgetcodcf

Return Thisform.PF.pgDocumento.txtCd_CF.Field.Value

ENDPROC


*======================================================================

*** CLASS / OBJECT: Spcar1 (BaseClass: textbox, Parent: cmd.PF.pgSelRigheAvanzata.cntPrelievoQta.Grid.ColCd_AR) ***
*** PROPERTIES ***
FontSize = 8

BorderStyle = 0

Left = 87

Margin = 0

Top = 30

fkhasdisplay = .F.

Name = "Spcar1"


*** METHODS ***
PROCEDURE fkgetcodcf

If Thisform.PF.pgSelTeste.cnt.txtCd_CF.Field.WcOperator = 1

	Return Thisform.PF.pgSelTeste.cnt.txtCd_CF.Field.Value 

Else

	Return ''

EndIf

ENDPROC

PROCEDURE onvaluechange

LPARAMETERS xoldvalue

LOCAL oARMisura

LOCAL cArMisura

LOCAL nUMFatt



IF !ISNULL(THIS.FKAliasRec) AND !EMPTY(THIS.FKAliasRec.Cd_ARMisura)

	oARMisura = xSqlExec2Obj('SELECT Cd_ARMisura, UMFatt FROM ARARMisura WHERE Cd_AR = ' + Format4Spt(ARQta.Cd_AR) + ' AND Cd_ARMisura = ' + Format4Spt(THIS.FKAliasRec.Cd_ARMisura))

ELSE

	oARMisura = xSqlExec2Obj('SELECT Cd_ARMisura, UMFatt FROM ARARMisura WHERE Cd_AR = ' + Format4Spt(ARQta.Cd_AR) + ' AND DefaultMisura = 1')

ENDIF



IF !ISNULL(oARMisura)

	cARMisura = oARMisura.Cd_ARMisura

	nUMFatt   = oARMisura.UMFatt

ELSE

	cARMisura = ''

	nUMFatt   = 1.0

ENDIF



REPLACE ;

	ARQta.Descrizione	WITH EVAL(THIS.FKAlias + '.Descrizione'), ;

	ARQta.UMFatt		WITH nUMFatt, ;

	ARQta.Cd_ARMisura	WITH cARMisura ;

	IN ARQta





ENDPROC


*======================================================================

*** CLASS / OBJECT: cntPrelievoQta (BaseClass: container, Parent: cmd.PF.pgSelRigheAvanzata) ***
*** PROPERTIES ***
Anchor = 15

Top = 1

Left = -1

Width = 683

Height = 416

BorderWidth = 0

TabIndex = 1

Name = "cntPrelievoQta"


*** METHODS ***
PROCEDURE Click

THIS.Grid.SetFocus()

THIS.Grid.WHEN()



ENDPROC

PROCEDURE Init

This.BorderWidth = 0

DoDefault()



ENDPROC


*======================================================================

*** CLASS / OBJECT: chkSoloArticoliPerQuantita (BaseClass: checkbox, Parent: cmd.PF.pgSelRigheAvanzata.cntPrelievoQta) ***
*** PROPERTIES ***
Comment = "E0D1B1C7-2191-48D3-A700-78CB5D55CBC8"

Top = 400

Left = 6

Anchor = 4

Alignment = 0

Caption = "Solo Articoli In Lista"

Value = .F.

ToolTipText = "verranno prelevate solamente le righe relative agli articoli della lista"

Name = "chkSoloArticoliPerQuantita"


*** METHODS ***
PROCEDURE Init



DODEFAULT()

** UP_SCOPE_USER, UP_SCOPE_COMP, UP_SCOPE_COMPUSER

This.Value = Thisform.UserPrefGetProperty(This, UP_SCOPE_COMPUSER, 'Value', .F.)







ENDPROC

PROCEDURE Destroy



** UP_SCOPE_USER, UP_SCOPE_COMP, UP_SCOPE_COMPUSER

Thisform.UserPrefSetProperty(This, UP_SCOPE_COMPUSER, 'Value', This.Value)





DODEFAULT()

ENDPROC

PROCEDURE Click

DoDefault()



This.Parent.chkQuantitaFissa.Enabled = This.Value

This.Parent.Grid.Enabled				 = This.Value

This.Parent.Grid.BackColor				 = Iif(This.Value, This.Parent.cmbVersoOrdinePrelievoARQta.BackColor, This.Parent.cmbVersoOrdinePrelievoARQta.DisabledBackColor)

This.Parent.Grid.OnFocus(This.Value)

ENDPROC


*======================================================================

*** CLASS / OBJECT: chkQuantitaFissa (BaseClass: checkbox, Parent: cmd.PF.pgSelRigheAvanzata.cntPrelievoQta) ***
*** PROPERTIES ***
Comment = "C9C35E48-59D3-4C2A-A305-F86B684266B3"

Top = 400

Left = 128

Anchor = 4

Alignment = 0

Caption = "Quantità Fissa"

Value = .F.

ToolTipText = "Genera automaticamente una riga di prelievo per le quantità non disponibili"

Name = "chkQuantitaFissa"


*** METHODS ***
PROCEDURE Init



DODEFAULT()

** UP_SCOPE_USER, UP_SCOPE_COMP, UP_SCOPE_COMPUSER

This.Value = Thisform.UserPrefGetProperty(This, UP_SCOPE_COMPUSER, 'Value', .F.)







ENDPROC

PROCEDURE Destroy



** UP_SCOPE_USER, UP_SCOPE_COMP, UP_SCOPE_COMPUSER

Thisform.UserPrefSetProperty(This, UP_SCOPE_COMPUSER, 'Value', This.Value)





DODEFAULT()

ENDPROC


*======================================================================

*** CLASS / OBJECT: cmbOrdinePrelievoARQta (BaseClass: combobox, Parent: cmd.PF.pgSelRigheAvanzata.cntPrelievoQta) ***
*** PROPERTIES ***
Comment = "0833020C-127B-4A62-92F9-C748EC40866A"

Anchor = 12

BoundColumn = 2

Height = 19

Left = 479

Top = 397

Width = 102

BoundTo = .T.

Name = "cmbOrdinePrelievoARQta"


*** METHODS ***
PROCEDURE onvaluechange

LPARAMETERS xoldvalue



** THIS.PARENT.cmbVersoOrdinePrelievoARQta.ENABLED = InList(This.ListIndex, 2, 3)

ENDPROC

PROCEDURE Init

DODEFAULT()



WITH This

	.AddItem('<Nessuno>')

	.List(.ListCount, 2) = ''

	

	.AddItem('Data Documento')

	.List(.ListCount, 2) = 'DoRig.DataDoc,DoRig.Id_DoTes,DoRig.Riga'

	

	.AddItem('Data Consegna')

	.List(.ListCount, 2) = 'DoRig.DataConsegna,DoRig.Id_DoTes,DoRig.Riga'



	.AddItem('Data Documento/Consegna')

	.List(.ListCount, 2) = 'DoRig.DataDoc,DoRig.DataConsegna,DoRig.Id_DoTes,DoRig.Riga'



	.ListIndex = 1

ENDWITH





ENDPROC


*======================================================================

*** CLASS / OBJECT: cmbVersoOrdinePrelievoARQta (BaseClass: combobox, Parent: cmd.PF.pgSelRigheAvanzata.cntPrelievoQta) ***
*** PROPERTIES ***
Comment = "B4940F35-C25D-4ABC-984A-446F6211662F"

Anchor = 12

BoundColumn = 2

Enabled = .F.

Height = 19

Left = 584

Top = 397

Width = 93

BoundTo = .T.

Name = "cmbVersoOrdinePrelievoARQta"


*** METHODS ***
PROCEDURE Init

DODEFAULT()



WITH This

	.AddItem('Crescente')

	.List(.ListCount, 2) = 'ASC'

	.AddItem('Decrescente')

	.List(.ListCount, 2) = 'DESC'

	.ListIndex = 1

ENDWITH





ENDPROC


*======================================================================

