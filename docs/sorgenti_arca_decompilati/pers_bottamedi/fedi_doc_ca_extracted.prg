*** Extracted Visual FoxPro Source Code from fedi_doc_ca.vcx ***

*** CLASS / OBJECT: de (BaseClass: container, Parent: ) ***
*** PROPERTIES ***
Name = "de"
DoTes.Name = "DoTes"
DORig.Name = "DORig"
DORigSpesa.Name = "DORigSpesa"
Impostazione.Name = "Impostazione"
DoDB.Name = "DoDB"
DoDBAttivita.Name = "DoDBAttivita"
DoDBMateriale.Name = "DoDBMateriale"
DOReport.Name = "DOReport"
DoRigPackList.Name = "DoRigPackList"
DOUICFG.Name = "DOUICFG"
CGLiq.Name = "CGLiq"

*** METHODS ***
PROCEDURE DoTes.Init
*
*	Fabrizio Gianotti	17/11/2016	Aggiungo i dati anagrafici della sede operativa
*

DoDefault()

Text To cSql TextMerge
	, SO1.Descrizione	As SO_Descrizione
	, SO1.Localita		As SO_Localita
	/*CIP*/
EndText

This.Stmt = STRTRAN(THIS.Stmt, '/*CIP*/', cSql)

TEXT TO xStmp TEXTMERGE
     LEFT JOIN CFDest SO1 ON SO1.CD_CfDest = DOTes.CD_CFDest And SO1.Cd_CF = DOTes.Cd_CF /*TIP*/
ENDTEXT

This.Stmt = StrTran(This.Stmt, '/*TIP*/', xStmp)

ENDPROC
PROCEDURE DoTes.initcolsinfo

DoDefault()

This.aColsInfo('SO_Descrizione').RemoteFullName = 'SO1.Descrizione'
This.aColsInfo('SO_Localita').RemoteFullName = 'SO1.Localita'
ENDPROC

*======================================================================

*** CLASS / OBJECT: elenco (BaseClass: container, Parent: ) ***
*** PROPERTIES ***
Name = "elenco"
Grid.ColId_DoTes.Header1.Name = "Header1"
Grid.ColId_DoTes.Text1.Name = "Text1"
Grid.ColId_DoTes.Name = "ColId_DoTes"
Grid.ColEsercizio.Header1.Name = "Header1"
Grid.ColEsercizio.Text1.Name = "Text1"
Grid.ColEsercizio.Name = "ColEsercizio"
Grid.ColTipoDocumento.Header1.Name = "Header1"
Grid.ColTipoDocumento.Text1.Name = "Text1"
Grid.ColTipoDocumento.Name = "ColTipoDocumento"
Grid.ColCd_Do.Header1.Name = "Header1"
Grid.ColCd_Do.Text1.Name = "Text1"
Grid.ColCd_Do.Name = "ColCd_Do"
Grid.ColNumeroDoc.Header1.Name = "Header1"
Grid.ColNumeroDoc.Text1.Name = "Text1"
Grid.ColNumeroDoc.Name = "ColNumeroDoc"
Grid.ColDataDoc.Header1.Name = "Header1"
Grid.ColDataDoc.Text1.Name = "Text1"
Grid.ColDataDoc.Name = "ColDataDoc"
Grid.ColNumeroDocRif.Header1.Name = "Header1"
Grid.ColNumeroDocRif.Text1.Name = "Text1"
Grid.ColNumeroDocRif.Name = "ColNumeroDocRif"
Grid.ColDataDocRif.Header1.Name = "Header1"
Grid.ColDataDocRif.Text1.Name = "Text1"
Grid.ColDataDocRif.Name = "ColDataDocRif"
Grid.ColCF.Header1.Name = "Header1"
Grid.ColCF.Text1.Name = "Text1"
Grid.ColCF.Name = "ColCF"
Grid.ColCFDesc.Header1.Name = "Header1"
Grid.ColCFDesc.Text1.Name = "Text1"
Grid.ColCFDesc.Name = "ColCFDesc"
Grid.ColCd_CFDest.Header1.Name = "Header1"
Grid.ColCd_CFDest.Text1.Name = "Text1"
Grid.ColCd_CFDest.Name = "ColCd_CFDest"
Grid.ColContatore.Header1.Name = "Header1"
Grid.ColContatore.Text1.Name = "Text1"
Grid.ColContatore.Name = "ColContatore"
Grid.ColCd_Agente_1.Header1.Name = "Header1"
Grid.ColCd_Agente_1.Text1.Name = "Text1"
Grid.ColCd_Agente_1.Name = "ColCd_Agente_1"
Grid.ColAgente_1_Descrizione.Header1.Name = "Header1"
Grid.ColAgente_1_Descrizione.Text1.Name = "Text1"
Grid.ColAgente_1_Descrizione.Name = "ColAgente_1_Descrizione"
Grid.ColCd_Agente_2.Header1.Name = "Header1"
Grid.ColCd_Agente_2.Text1.Name = "Text1"
Grid.ColCd_Agente_2.Name = "ColCd_Agente_2"
Grid.ColAgente_2_Descrizione.Header1.Name = "Header1"
Grid.ColAgente_2_Descrizione.Text1.Name = "Text1"
Grid.ColAgente_2_Descrizione.Name = "ColAgente_2_Descrizione"
Grid.ColCd_VL.Header1.Name = "Header1"
Grid.ColCd_VL.Text1.Name = "Text1"
Grid.ColCd_VL.Name = "ColCd_VL"
Grid.ColCambio.Header1.Name = "Header1"
Grid.ColCambio.Text1.Name = "Text1"
Grid.ColCambio.Name = "ColCambio"
Grid.ColCd_PG.Header1.Name = "Header1"
Grid.ColCd_PG.Text1.Name = "Text1"
Grid.ColCd_PG.Name = "ColCd_PG"
Grid.ColCd_LS_1.Header1.Name = "Header1"
Grid.ColCd_LS_1.Text1.Name = "Text1"
Grid.ColCd_LS_1.Name = "ColCd_LS_1"
Grid.ColCd_LS_2.Header1.Name = "Header1"
Grid.ColCd_LS_2.Text1.Name = "Text1"
Grid.ColCd_LS_2.Name = "ColCd_LS_2"
Grid.Colcd_DOCommessa.Header1.Name = "Header1"
Grid.Colcd_DOCommessa.Text1.Name = "Text1"
Grid.Colcd_DOCommessa.Name = "Colcd_DOCommessa"
Grid.ColRighe.Header1.Name = "Header1"
Grid.ColRighe.Text1.Name = "Text1"
Grid.ColRighe.Name = "ColRighe"
Grid.ColRigheEvadibili.Header1.Name = "Header1"
Grid.ColRigheEvadibili.Text1.Name = "Text1"
Grid.ColRigheEvadibili.Name = "ColRigheEvadibili"
Grid.ColAccontoV.Header1.Name = "Header1"
Grid.ColAccontoV.Text1.Name = "Text1"
Grid.ColAccontoV.Name = "ColAccontoV"
Grid.ColAbbuonoV.Header1.Name = "Header1"
Grid.ColAbbuonoV.Text1.Name = "Text1"
Grid.ColAbbuonoV.Name = "ColAbbuonoV"
Grid.ColTotDocumentoV.Header1.Name = "Header1"
Grid.ColTotDocumentoV.Text1.Name = "Text1"
Grid.ColTotDocumentoV.Name = "ColTotDocumentoV"
Grid.ColEsecutivo.Header1.Name = "Header1"
Grid.ColEsecutivo.Text1.Name = "Text1"
Grid.ColEsecutivo.Name = "ColEsecutivo"
Grid.ColPrelevabile.Header1.Name = "Header1"
Grid.ColPrelevabile.Text1.Name = "Text1"
Grid.ColPrelevabile.Name = "ColPrelevabile"
Grid.ColModificabile.Header1.Name = "Header1"
Grid.ColModificabile.Text1.Name = "Text1"
Grid.ColModificabile.Name = "ColModificabile"
Grid.ColIvaSospesa.Hdrbase1.Name = "Hdrbase1"
Grid.ColIvaSospesa.Text1.Name = "Text1"
Grid.ColIvaSospesa.Name = "ColIvaSospesa"
Grid.Col_OCScaduto.Hdrbase1.Name = "Hdrbase1"
Grid.Col_OCScaduto.Text1.Name = "Text1"
Grid.Col_OCScaduto.Name = "Col_OCScaduto"
Grid.ColNettoaPagare.Hdrbase1.Name = "Hdrbase1"
Grid.ColNettoaPagare.Text1.Name = "Text1"
Grid.ColNettoaPagare.Name = "ColNettoaPagare"
Grid.Col_statoFte.Hdrbase1.Name = "Hdrbase1"
Grid.Col_statoFte.Text1.Name = "Text1"
Grid.Col_statoFte.Name = "Col_statoFte"
Grid.Name = "Grid"
lblLegend06a.Stdlabel4.Name = "Stdlabel4"
lblLegend06a.Name = "lblLegend06a"
lblLegend02a.Name = "lblLegend02a"
lblLegend07a.Stdlabel4.Name = "Stdlabel4"
lblLegend07a.Name = "lblLegend07a"
lblLegend01a.Name = "lblLegend01a"
lblLegend02b.Name = "lblLegend02b"
lblLegend01b.Name = "lblLegend01b"

*** METHODS ***
PROCEDURE Grid.Init
Local oCol1, oCol2
	
	** Grid.Init
	** Campo descrizione destinazione diversa (Sede operativa)
	oCol1 = This.newColumn('xColDescDest', 'DOTes.SO_Descrizione', 'Destinazione', 100)
	oCol1.enabled = .F.
	oCol1.ReadOnly = .T.
	
	** Campo località destinazione diversa (Località sede operativa)
	oCol2 = This.newColumn('xColLocDest', 'DOTes.SO_Localita', 'Luogo destinazione', 100)
	oCol2.enabled = .F.
	oCol2.ReadOnly = .T.
	
DODEFAULT()
ENDPROC

*======================================================================

*** CLASS / OBJECT: fedi (BaseClass: form, Parent: ) ***
*** PROPERTIES ***
DoCreate = .T.
Name = "fedi"
statusbar.Top = 528
statusbar.Left = 0
statusbar.Height = 20
statusbar.Width = 652
statusbar.Name = "statusbar"
timer4ExecAsync.Name = "timer4ExecAsync"
title_bar.BtnLabel.Name = "BtnLabel"
title_bar.lblLabel.Name = "lblLabel"
title_bar.Name = "title_bar"
SCMenu.Name = "SCMenu"
tbenabler.Name = "tbenabler"
imgRecInfo.Height = 16
imgRecInfo.Width = 16
imgRecInfo.Name = "imgRecInfo"
PF.ErasePage = .T.
PF.pgElenco.PageOrder = 1
PF.pgElenco.Name = "pgElenco"
PF.pgGenerale.PF.ErasePage = .T.
PF.pgGenerale.PF.pgGenerale.cntconservazioneinvio.TITLE.Name = "TITLE"
PF.pgGenerale.PF.pgGenerale.cntconservazioneinvio.imgModificabileImmaginePdf.Name = "imgModificabileImmaginePdf"
PF.pgGenerale.PF.pgGenerale.cntconservazioneinvio.imgConservato.Name = "imgConservato"
PF.pgGenerale.PF.pgGenerale.cntconservazioneinvio.lnkDms.field.Alignment = 0
PF.pgGenerale.PF.pgGenerale.cntconservazioneinvio.lnkDms.field.Name = "field"
PF.pgGenerale.PF.pgGenerale.cntconservazioneinvio.lnkDms.Name = "lnkDms"
PF.pgGenerale.PF.pgGenerale.cntconservazioneinvio.lblStatus.Name = "lblStatus"
PF.pgGenerale.PF.pgGenerale.cntconservazioneinvio.step1.Name = "step1"
PF.pgGenerale.PF.pgGenerale.cntconservazioneinvio.step2.Name = "step2"
PF.pgGenerale.PF.pgGenerale.cntconservazioneinvio.step3.Name = "step3"
PF.pgGenerale.PF.pgGenerale.cntconservazioneinvio.Name = "cntconservazioneinvio"
PF.pgGenerale.PF.pgGenerale.cntpeppol.TITLE.Name = "TITLE"
PF.pgGenerale.PF.pgGenerale.cntpeppol.btnView.Name = "btnView"
PF.pgGenerale.PF.pgGenerale.cntpeppol.btnUpload.Name = "btnUpload"
PF.pgGenerale.PF.pgGenerale.cntpeppol.btnState.Name = "btnState"
PF.pgGenerale.PF.pgGenerale.cntpeppol.Name = "cntpeppol"
PF.pgGenerale.PF.pgGenerale.txtCF_Fatt.TITLE.Name = "TITLE"
PF.pgGenerale.PF.pgGenerale.txtCF_Fatt.field.Name = "field"
PF.pgGenerale.PF.pgGenerale.txtCF_Fatt.Display.Name = "Display"
PF.pgGenerale.PF.pgGenerale.txtCF_Fatt.Name = "txtCF_Fatt"
PF.pgGenerale.PF.pgGenerale.cntPagamento.txtCd_PG.Label.Name = "Label"
PF.pgGenerale.PF.pgGenerale.cntPagamento.txtCd_PG.field.Name = "field"
PF.pgGenerale.PF.pgGenerale.cntPagamento.txtCd_PG.Display.Name = "Display"
PF.pgGenerale.PF.pgGenerale.cntPagamento.txtCd_PG.Name = "txtCd_PG"
PF.pgGenerale.PF.pgGenerale.cntPagamento.TITLE.Name = "TITLE"
PF.pgGenerale.PF.pgGenerale.cntPagamento.txtCd_Agente.Label.Name = "Label"
PF.pgGenerale.PF.pgGenerale.cntPagamento.txtCd_Agente.field.Name = "field"
PF.pgGenerale.PF.pgGenerale.cntPagamento.txtCd_Agente.Display.Name = "Display"
PF.pgGenerale.PF.pgGenerale.cntPagamento.txtCd_Agente.Field1.Name = "Field1"
PF.pgGenerale.PF.pgGenerale.cntPagamento.txtCd_Agente.Name = "txtCd_Agente"
PF.pgGenerale.PF.pgGenerale.cntPagamento.txtScontoCassa.Label.Name = "Label"
PF.pgGenerale.PF.pgGenerale.cntPagamento.txtScontoCassa.field.Name = "field"
PF.pgGenerale.PF.pgGenerale.cntPagamento.txtScontoCassa.Name = "txtScontoCassa"
PF.pgGenerale.PF.pgGenerale.cntPagamento.txtDataPag.Label.Name = "Label"
PF.pgGenerale.PF.pgGenerale.cntPagamento.txtDataPag.field.Name = "field"
PF.pgGenerale.PF.pgGenerale.cntPagamento.txtDataPag.Name = "txtDataPag"
PF.pgGenerale.PF.pgGenerale.cntPagamento.Name = "cntPagamento"
PF.pgGenerale.PF.pgGenerale.cntVarie.txtCd_CFZona.Label.Name = "Label"
PF.pgGenerale.PF.pgGenerale.cntVarie.txtCd_CFZona.field.Name = "field"
PF.pgGenerale.PF.pgGenerale.cntVarie.txtCd_CFZona.Display.Name = "Display"
PF.pgGenerale.PF.pgGenerale.cntVarie.txtCd_CFZona.Name = "txtCd_CFZona"
PF.pgGenerale.PF.pgGenerale.cntVarie.TITLE.Name = "TITLE"
PF.pgGenerale.PF.pgGenerale.cntVarie.txtDataConsegna.Label.Name = "Label"
PF.pgGenerale.PF.pgGenerale.cntVarie.txtDataConsegna.field.Name = "field"
PF.pgGenerale.PF.pgGenerale.cntVarie.txtDataConsegna.Name = "txtDataConsegna"
PF.pgGenerale.PF.pgGenerale.cntVarie.txtCd_Commessa.Label.Name = "Label"
PF.pgGenerale.PF.pgGenerale.cntVarie.txtCd_Commessa.field.Name = "field"
PF.pgGenerale.PF.pgGenerale.cntVarie.txtCd_Commessa.Name = "txtCd_Commessa"
PF.pgGenerale.PF.pgGenerale.cntVarie.Name = "cntVarie"
PF.pgGenerale.PF.pgGenerale.cntStato.TITLE.Name = "TITLE"
PF.pgGenerale.PF.pgGenerale.cntStato.chkEsecutivo.Alignment = 0
PF.pgGenerale.PF.pgGenerale.cntStato.chkEsecutivo.Name = "chkEsecutivo"
PF.pgGenerale.PF.pgGenerale.cntStato.chkPrelevabile.Alignment = 0
PF.pgGenerale.PF.pgGenerale.cntStato.chkPrelevabile.Name = "chkPrelevabile"
PF.pgGenerale.PF.pgGenerale.cntStato.chkModificabile.Alignment = 0
PF.pgGenerale.PF.pgGenerale.cntStato.chkModificabile.Name = "chkModificabile"
PF.pgGenerale.PF.pgGenerale.cntStato.Name = "cntStato"
PF.pgGenerale.PF.pgGenerale.txtNumeroDataRif.Label.Name = "Label"
PF.pgGenerale.PF.pgGenerale.txtNumeroDataRif.field.Name = "field"
PF.pgGenerale.PF.pgGenerale.txtNumeroDataRif.Field1.Name = "Field1"
PF.pgGenerale.PF.pgGenerale.txtNumeroDataRif.TITLE.Name = "TITLE"
PF.pgGenerale.PF.pgGenerale.txtNumeroDataRif.Lblbase1.Name = "Lblbase1"
PF.pgGenerale.PF.pgGenerale.txtNumeroDataRif.Name = "txtNumeroDataRif"
PF.pgGenerale.PF.pgGenerale.cntDatiContabili.txtCd_CGConto_BnSc.Label.Name = "Label"
PF.pgGenerale.PF.pgGenerale.cntDatiContabili.txtCd_CGConto_BnSc.field.Name = "field"
PF.pgGenerale.PF.pgGenerale.cntDatiContabili.txtCd_CGConto_BnSc.Display.Name = "Display"
PF.pgGenerale.PF.pgGenerale.cntDatiContabili.txtCd_CGConto_BnSc.Name = "txtCd_CGConto_BnSc"
PF.pgGenerale.PF.pgGenerale.cntDatiContabili.TITLE.Name = "TITLE"
PF.pgGenerale.PF.pgGenerale.cntDatiContabili.TxtIban.Label.Name = "Label"
PF.pgGenerale.PF.pgGenerale.cntDatiContabili.TxtIban.field.Name = "field"
PF.pgGenerale.PF.pgGenerale.cntDatiContabili.TxtIban.Name = "TxtIban"
PF.pgGenerale.PF.pgGenerale.cntDatiContabili.txtBic.Label.Name = "Label"
PF.pgGenerale.PF.pgGenerale.cntDatiContabili.txtBic.field.Name = "field"
PF.pgGenerale.PF.pgGenerale.cntDatiContabili.txtBic.Name = "txtBic"
PF.pgGenerale.PF.pgGenerale.cntDatiContabili.ChkIvaSospesa.Alignment = 0
PF.pgGenerale.PF.pgGenerale.cntDatiContabili.ChkIvaSospesa.Name = "ChkIvaSospesa"
PF.pgGenerale.PF.pgGenerale.cntDatiContabili.chkCGCorrispondenzaIvaMerce.Alignment = 7
PF.pgGenerale.PF.pgGenerale.cntDatiContabili.chkCGCorrispondenzaIvaMerce.Name = "chkCGCorrispondenzaIvaMerce"
PF.pgGenerale.PF.pgGenerale.cntDatiContabili.chkIvaSplit.Alignment = 0
PF.pgGenerale.PF.pgGenerale.cntDatiContabili.chkIvaSplit.Name = "chkIvaSplit"
PF.pgGenerale.PF.pgGenerale.cntDatiContabili.txtCd_ReverseCharge.Label.Name = "Label"
PF.pgGenerale.PF.pgGenerale.cntDatiContabili.txtCd_ReverseCharge.field.Name = "field"
PF.pgGenerale.PF.pgGenerale.cntDatiContabili.txtCd_ReverseCharge.Display.Name = "Display"
PF.pgGenerale.PF.pgGenerale.cntDatiContabili.txtCd_ReverseCharge.Name = "txtCd_ReverseCharge"
PF.pgGenerale.PF.pgGenerale.cntDatiContabili.Name = "cntDatiContabili"
PF.pgGenerale.PF.pgGenerale.txtCd_LS.Label.Name = "Label"
PF.pgGenerale.PF.pgGenerale.txtCd_LS.field.Name = "field"
PF.pgGenerale.PF.pgGenerale.txtCd_LS.Display.Name = "Display"
PF.pgGenerale.PF.pgGenerale.txtCd_LS.Field1.Name = "Field1"
PF.pgGenerale.PF.pgGenerale.txtCd_LS.Display1.Name = "Display1"
PF.pgGenerale.PF.pgGenerale.txtCd_LS.Field2.Name = "Field2"
PF.pgGenerale.PF.pgGenerale.txtCd_LS.Display2.Name = "Display2"
PF.pgGenerale.PF.pgGenerale.txtCd_LS.TITLE.Name = "TITLE"
PF.pgGenerale.PF.pgGenerale.txtCd_LS.Name = "txtCd_LS"
PF.pgGenerale.PF.pgGenerale.edtNotePiede.Field1.Name = "Field1"
PF.pgGenerale.PF.pgGenerale.edtNotePiede.Label.Name = "Label"
PF.pgGenerale.PF.pgGenerale.edtNotePiede.grdNote.Column1.Header1.Name = "Header1"
PF.pgGenerale.PF.pgGenerale.edtNotePiede.grdNote.Column1.Text1.Name = "Text1"
PF.pgGenerale.PF.pgGenerale.edtNotePiede.grdNote.Column1.Name = "Column1"
PF.pgGenerale.PF.pgGenerale.edtNotePiede.grdNote.Name = "grdNote"
PF.pgGenerale.PF.pgGenerale.edtNotePiede.field.Name = "field"
PF.pgGenerale.PF.pgGenerale.edtNotePiede.TITLE.Name = "TITLE"
PF.pgGenerale.PF.pgGenerale.edtNotePiede.Name = "edtNotePiede"
PF.pgGenerale.PF.pgGenerale.Name = "pgGenerale"
PF.pgGenerale.PF.pgrighe.Name = "pgrighe"
PF.pgGenerale.PF.pgpiede.Name = "pgpiede"
PF.pgGenerale.PF.pgtotali.Name = "pgtotali"
PF.pgGenerale.PF.pgevasioni.Name = "pgevasioni"
PF.pgGenerale.PF.pgmoduli.Name = "pgmoduli"
PF.pgGenerale.PF.Name = "PF"
PF.pgGenerale.txtCd_DO.Label.Name = "Label"
PF.pgGenerale.txtCd_DO.field.Name = "field"
PF.pgGenerale.txtCd_DO.Name = "txtCd_DO"
PF.pgGenerale.txtDataDoc.Label.Name = "Label"
PF.pgGenerale.txtDataDoc.field.Name = "field"
PF.pgGenerale.txtDataDoc.Name = "txtDataDoc"
PF.pgGenerale.txtCd_CF.Label.Name = "Label"
PF.pgGenerale.txtCd_CF.field.Name = "field"
PF.pgGenerale.txtCd_CF.Name = "txtCd_CF"
PF.pgGenerale.txtCd_VL.Label.Name = "Label"
PF.pgGenerale.txtCd_VL.field.Name = "field"
PF.pgGenerale.txtCd_VL.Display.Name = "Display"
PF.pgGenerale.txtCd_VL.Name = "txtCd_VL"
PF.pgGenerale.txtCambio.Label.Name = "Label"
PF.pgGenerale.txtCambio.field.Name = "field"
PF.pgGenerale.txtCambio.Name = "txtCambio"
PF.pgGenerale.txtCFDest.Label.Name = "Label"
PF.pgGenerale.txtCFDest.field.Name = "field"
PF.pgGenerale.txtCFDest.Display.Name = "Display"
PF.pgGenerale.txtCFDest.Name = "txtCFDest"
PF.pgGenerale.txtNumeroDoc.Label.Name = "Label"
PF.pgGenerale.txtNumeroDoc.field.Name = "field"
PF.pgGenerale.txtNumeroDoc.Name = "txtNumeroDoc"
PF.pgGenerale.cntTesta2.ddrow1.Name = "ddrow1"
PF.pgGenerale.cntTesta2.ddrow2.Name = "ddrow2"
PF.pgGenerale.cntTesta2.SORow.Name = "SORow"
PF.pgGenerale.cntTesta2.Name = "cntTesta2"
PF.pgGenerale.txtCFSede.Label.Name = "Label"
PF.pgGenerale.txtCFSede.field.Name = "field"
PF.pgGenerale.txtCFSede.Display.Name = "Display"
PF.pgGenerale.txtCFSede.Name = "txtCFSede"
PF.pgGenerale.PageOrder = 2
PF.pgGenerale.Name = "pgGenerale"
PF.pgallegati.PageOrder = 3
PF.pgallegati.Name = "pgallegati"
PF.Name = "PF"

*** METHODS ***
PROCEDURE xassegnapesonetto
&& Calcola la superfice (Quantità) in base a Colli,Tara e peso lordo
LOCAL nColli, nLordo, nTara, nPesoNetto,  QtaRes, QtaOri
		
	nColli 	= DoRig.xColli
	nLordo 	= DoRig.xLordo
	nTara  	= DoRig.xTara
	QtaOri 	= DoRig.Qta && Qta/PesoNetto originale
	IF !EMPTY(nLordo) THEN 	
	   	nPesoNetto = nLordo - (nColli * nTara)
	   	ELSE
	   	nPesoNetto = nColli
	ENDIF
	
   	REPLACE Qta 			WITH nPesoNetto	IN DoRig
   	
    QtaRes = DoRig.QtaEvadibile + (DoRig.Qta - QtaOri)
   	REPLACE QtaEvadibile	WITH QtaRes		IN DoRig   		   

RETURN nPesoNetto
ENDPROC
PROCEDURE save
LParameters lInsertMode
LOCAL xImpostaLotto
LOCAL nOldWA
LOCAL cSql
LOCAL nErrors

DODEFAULT(lInsertMode) && Operazioni standard di salvataggio

nErrors = 0
xImpostaLotto = THISForm.PF.Pggenerale.txtcd_DO.Field.fkrecord.xLTAutoSave
IF lInsertMode AND xImpostaLotto THEN 
	&& Imposto i lotti utilizzati come predefiniti (articolo per articolo)
	nOldWA = SELECT(0)	&& Imposto l'attuale WorkArea
	SELECT DoRig
	SCAN
		IF !IsEmpty(DoRig.Cd_AR) AND !IsEmpty(DoRig.Cd_ARLotto) THEN
			TEXT TO cSQL TEXTMERGE PRETEXT 7
				UPDATE AR 
				SET xCd_ARLottoP = <<Format4SPT(DoRig.Cd_ARLotto)>>
				WHERE Cd_AR = <<Format4SPT(DoRig.Cd_AR)>>
			ENDTEXT
			_CLIPTEXT = cSql
			IF xSqlExec(cSQL , , .T.) < 0 THEN
				nErrors  = nErrors + 1
			ENDIF
		ENDIF
	ENDSCAN
	IF nErrors > 0 THEN 
		xMessageBox('Attenzione: si sono verificati errori in fase di aggiornamento dei lotti predefiniti')
	ENDIF
	SELECT (nOldWA)	&& Reimposto la Workarea originaria
ENDIF
ENDPROC
PROCEDURE runreport
LParameters nAction, cUd_ReportDoc
IF DoTes.Esecutivo = .T. THEN 
	DODEFAULT(nAction, cUd_ReportDoc)
ENDIF
ENDPROC

*======================================================================

*** CLASS / OBJECT: pgrighe (BaseClass: container, Parent: ) ***
*** PROPERTIES ***
Width = 726
Height = 311
Name = "pgrighe"
Grid.ColRiga.Header1.Name = "Header1"
Grid.ColRiga.Text1.Name = "Text1"
Grid.ColRiga.Name = "ColRiga"
Grid.ColCd_AR.Header1.Name = "Header1"
Grid.ColCd_AR.stdText1.Name = "stdText1"
Grid.ColCd_AR.Name = "ColCd_AR"
Grid.ColDescrizione.Header1.Name = "Header1"
Grid.ColDescrizione.Text1.Name = "Text1"
Grid.ColDescrizione.Name = "ColDescrizione"
Grid.ColCd_ARMisura.Header1.Name = "Header1"
Grid.ColCd_ARMisura.Text1.Name = "Text1"
Grid.ColCd_ARMisura.Name = "ColCd_ARMisura"
Grid.ColFattoreToUM1.Header1.Name = "Header1"
Grid.ColFattoreToUM1.Text1.Name = "Text1"
Grid.ColFattoreToUM1.Name = "ColFattoreToUM1"
Grid.COLQTA.Header1.Name = "Header1"
Grid.COLQTA.stdText1.Name = "stdText1"
Grid.COLQTA.Name = "COLQTA"
Grid.COLQTAEVADIBILE.Header1.Name = "Header1"
Grid.COLQTAEVADIBILE.Text1.Name = "Text1"
Grid.COLQTAEVADIBILE.Name = "COLQTAEVADIBILE"
Grid.ColPrezzoUnitarioV.PrezzoUnitarioV.Name = "PrezzoUnitarioV"
Grid.ColPrezzoUnitarioV.Text1.Name = "Text1"
Grid.ColPrezzoUnitarioV.Name = "ColPrezzoUnitarioV"
Grid.ColScontoRiga.Header1.Name = "Header1"
Grid.ColScontoRiga.Text1.Name = "Text1"
Grid.ColScontoRiga.Name = "ColScontoRiga"
Grid.ColPrezzoTotaleV.Header1.Name = "Header1"
Grid.ColPrezzoTotaleV.Text1.Name = "Text1"
Grid.ColPrezzoTotaleV.Name = "ColPrezzoTotaleV"
Grid.ColCd_Aliquota.Header1.Name = "Header1"
Grid.ColCd_Aliquota.stdText1.Name = "stdText1"
Grid.ColCd_Aliquota.Name = "ColCd_Aliquota"
Grid.ColCd_CGConto.Header1.Name = "Header1"
Grid.ColCd_CGConto.spcConto1.Name = "spcConto1"
Grid.ColCd_CGConto.Name = "ColCd_CGConto"
Grid.ColProvvigioneRiga_1.Header1.Name = "Header1"
Grid.ColProvvigioneRiga_1.Text1.Name = "Text1"
Grid.ColProvvigioneRiga_1.Name = "ColProvvigioneRiga_1"
Grid.ColDataConsegna.Header1.Name = "Header1"
Grid.ColDataConsegna.Text1.Name = "Text1"
Grid.ColDataConsegna.Name = "ColDataConsegna"
Grid.ColProvvigioneRiga_2.Header1.Name = "Header1"
Grid.ColProvvigioneRiga_2.Text1.Name = "Text1"
Grid.ColProvvigioneRiga_2.Name = "ColProvvigioneRiga_2"
Grid.ColCd_MG_P.Header1.Name = "Header1"
Grid.ColCd_MG_P.stdText1.Name = "stdText1"
Grid.ColCd_MG_P.Name = "ColCd_MG_P"
Grid.ColCd_MG_A.Header1.Name = "Header1"
Grid.ColCd_MG_A.stdText1.Name = "stdText1"
Grid.ColCd_MG_A.Name = "ColCd_MG_A"
Grid.ColCd_ARLotto.Header1.Name = "Header1"
Grid.ColCd_ARLotto.stdText1.Name = "stdText1"
Grid.ColCd_ARLotto.Name = "ColCd_ARLotto"
Grid.ColCd_MGUbicazione_P.Header1.Name = "Header1"
Grid.ColCd_MGUbicazione_P.stdText1.Name = "stdText1"
Grid.ColCd_MGUbicazione_P.Name = "ColCd_MGUbicazione_P"
Grid.ColCd_MGUbicazione_A.Header1.Name = "Header1"
Grid.ColCd_MGUbicazione_A.stdText1.Name = "stdText1"
Grid.ColCd_MGUbicazione_A.Name = "ColCd_MGUbicazione_A"
Grid.ColCd_DOSottoCommessa.Header1.Name = "Header1"
Grid.ColCd_DOSottoCommessa.stdText1.Name = "stdText1"
Grid.ColCd_DOSottoCommessa.Name = "ColCd_DOSottoCommessa"
Grid.ColDettagli.Header1.Name = "Header1"
Grid.ColDettagli.btnDettaglio.Name = "btnDettaglio"
Grid.ColDettagli.Name = "ColDettagli"
Grid.COLDISTINTA.Header1.Name = "Header1"
Grid.COLDISTINTA.btnDistinta.Name = "btnDistinta"
Grid.COLDISTINTA.BTNNODISTINTA.Name = "BTNNODISTINTA"
Grid.COLDISTINTA.Name = "COLDISTINTA"
Grid.ColCd_CAVda.Header1.Name = "Header1"
Grid.ColCd_CAVda.spcCaVda1.Name = "spcCaVda1"
Grid.ColCd_CAVda.Name = "ColCd_CAVda"
Grid.ColCd_CACda.Header1.Name = "Header1"
Grid.ColCd_CACda.spcCaCda1.Name = "spcCaCda1"
Grid.ColCd_CACda.Name = "ColCd_CACda"
Grid.ColCd_CAFormula.Header1.Name = "Header1"
Grid.ColCd_CAFormula.Text1.Name = "Text1"
Grid.ColCd_CAFormula.Name = "ColCd_CAFormula"
Grid.COLCAPARTENZA.Header1.Name = "Header1"
Grid.COLCAPARTENZA.Text1.Name = "Text1"
Grid.COLCAPARTENZA.cmb_caofs.Name = "cmb_caofs"
Grid.COLCAPARTENZA.Name = "COLCAPARTENZA"
Grid.COLCADURATA.Header1.Name = "Header1"
Grid.COLCADURATA.Text1.Name = "Text1"
Grid.COLCADURATA.Name = "COLCADURATA"
Grid.ColRR_DataInizio.Header1.Name = "Header1"
Grid.ColRR_DataInizio.Text1.Name = "Text1"
Grid.ColRR_DataInizio.Name = "ColRR_DataInizio"
Grid.ColRR_DataFine.Header1.Name = "Header1"
Grid.ColRR_DataFine.Text1.Name = "Text1"
Grid.ColRR_DataFine.Name = "ColRR_DataFine"
Grid.ColRR_Cd_CGConto.Header1.Name = "Header1"
Grid.ColRR_Cd_CGConto.Text1.Name = "Text1"
Grid.ColRR_Cd_CGConto.Name = "ColRR_Cd_CGConto"
Grid.ColTipoPC.Header1.Name = "Header1"
Grid.ColTipoPC.Text1.Name = "Text1"
Grid.ColTipoPC.Name = "ColTipoPC"
Grid.colNote.Header1.Name = "Header1"
Grid.colNote.Text.Name = "Text"
Grid.colNote.stdedit.Name = "stdedit"
Grid.colNote.Name = "colNote"
Grid.colMatricole.Stdheader1.Name = "Stdheader1"
Grid.colMatricole.txtMatricole.Name = "txtMatricole"
Grid.colMatricole.txtEmpty.Name = "txtEmpty"
Grid.colMatricole.Name = "colMatricole"
Grid.COLCD_REVERSECHARGE.Stdheader1.Name = "Stdheader1"
Grid.COLCD_REVERSECHARGE.Text1.Name = "Text1"
Grid.COLCD_REVERSECHARGE.Name = "COLCD_REVERSECHARGE"
Grid.ColDoIntento.Stdheader1.Name = "Stdheader1"
Grid.ColDoIntento.STDTEXT1.Name = "STDTEXT1"
Grid.ColDoIntento.Name = "ColDoIntento"
Grid.Name = "Grid"
TITLE.Name = "TITLE"
lblLegend06a.Stdlabel4.Name = "Stdlabel4"
lblLegend06a.Top = 286
lblLegend06a.Left = 662
lblLegend06a.Name = "lblLegend06a"
lblLegend03.Left = 3
lblLegend03.Top = 288
lblLegend03.Name = "lblLegend03"
lblLegend02.Left = 20
lblLegend02.Top = 287
lblLegend02.Name = "lblLegend02"

*** METHODS ***
PROCEDURE xnettoonvaluechange
Lparameters xOldValue

LOCAL xPesoNetto

IF !((BITAND(ThisForm.Mode, FEDIMODE_EDIT) = 0) AND (BITAND(ThisForm.Mode, FEDIMODE_INS_DUP) = 0)) THEN 
	xPesoNetto = THISFORM.xAssegnaPesoNetto()
	** THIS.Grid.ColQTA.StdText1.Setvalue(xSuperfice)
ENDIF
DODEFAULT(xOldValue)
ENDPROC
PROCEDURE xnettoisvalid
Lparameters lIsChanged, xOldValue
LOCAL xPesoNetto


IF !((BITAND(ThisForm.Mode, FEDIMODE_EDIT) = 0) AND (BITAND(ThisForm.Mode, FEDIMODE_INS_DUP) = 0)) THEN 
	xPesoNetto = THISFORM.xAssegnaPesoNetto()
	THIS.Grid.ColPrezzoUnitarioV.Text1.OnValueChange(DoRig.PrezzoUnitarioV-1) 
	&& THIS.Grid.ColQTA.StdText1.Setvalue(xPesoNetto)
	&& THIS.Grid.ColQTA.StdText1.IsValid(lIsChanged, xOldPesoNetto) 
ENDIF
RETURN DODEFAULT(lIsChanged, xOldValue)
ENDPROC
PROCEDURE xmyreadini
&& xMyReadIni
PARAMETERS cIniFile, cSection, cEntry 

LOCAL ret_val


   DECLARE INTEGER GetPrivateProfileString IN Win32API  AS GetPrivStr ;
                                           String cSection, String cKey, String cDefault, String @cBuffer, ;
                                           Integer nBufferSize, String cINIFile

   ret_val = SPACE(1024)
   GetPrivStr(cSection, cEntry,"",@ret_val,1024,cIniFile)

RETURN STRTRAN(ALLTRIM(ret_val), CHR(0), "")

ENDPROC
PROCEDURE xgetclientname
&& xGetClientName
LOCAL cName

cName = UPPER(ALLTRIM(GETENV("CLIENTNAME"))) && Solo terminal server
IF EMPTY(cName) OR (cName = "CONSOLE") THEN 
   cName = UPPER(ALLTRIM(GETENV("COMPUTERNAME"))) && Computername 
ENDIF
RETURN cName
ENDPROC
PROCEDURE xgetbackupfilename
&& xGetBackupFilename
PARAMETER cFileASCII 

LOCAL cPath
LOCAL cFileBackup
LOCAL TempString
LOCAL cNuovoNome

** Calcolo il percorso della cartella di backup a partire da quella dove si trova il file ascii da leggere
cPath = JUSTPATH(cFileAscii) + '\NFILE_BAK'
cFileBackup = '' && Nome file vuoto = nessun backup
IF DIRECTORY(cPath) 	
	** Se la cartella esiste, determino il nome del file con il quale fare il backup
	TempString = DTOC(DATE())
	cNuovoNome = SUBSTR(TempString, 7, 4)  +  SUBSTR(TempString, 4, 2) + SUBSTR(TempString, 1, 2) + '_'  
	TempString = TIME()
	cNuovoNome = cNuovoNome + SUBSTR(TempString, 1, 2) + SUBSTR(TempString, 4, 2) + '.txt'
	cFileBackup = cPath  + '\' + cNuovoNome
ENDIF	

RETURN cFileBackup
ENDPROC
PROCEDURE xgetasciifilename
&& xGetAsciiFilename
LOCAL cFileASCII 
LOCAL cPath
LOCAL cDefaultFile

cPath = oApp.PersDir + '\' && DoImportAscii\
cDefaultFile = cPath + 'DoImportAscii\Data.txt'
IF FILE(cPath + 'NFile.Ini') 
	** Nel file NFile.Ini è eventualmente definito il nome del file ASCII da leggere
	** cFileASCII = UPPER(ReadIni(cPath + 'NFile.ini', 'Nomi', cPath + 'Data.Txt'))
	cFileASCII = UPPER(THIS.xMyReadIni(cPath + 'NFile.ini', 'Nomi', 'FileName'))
	IF cFileASCII = '' THEN 
	   cFileASCII = cDefaultFile
	ENDIF	
	&& Sostituisco le eventuali variabili del file name (es. <COMPUTERNAME>) 
	cFileASCII = STRTRAN(cFileASCII, '<COMPUTERNAME>', THIS.xGetClientName())	
	ELSE
	cFileASCII = cDefaultFile
ENDIF	
** xMessageBox(cFileAscii)
RETURN cFileASCII

ENDPROC
PROCEDURE xgetpricebydest
PARAMETERS myCd_CF, myCd_CFDest, myCd_AR
LOCAL cSql
LOCAL oRec
&& xMessageBox( myCd_CF + ' ' + myCd_CFDest + ' ' + myCd_AR )
IF !IsEmpty(myCd_CF) And !IsEmpty(myCd_CFDest) And !IsEmpty(myCd_AR) THEN 
	TEXT TO cSQL TEXTMERGE PRETEXT 7		
		SELECT TOP 1 Prezzo, Sconto FROM xARListDest
		WHERE Cd_CF = <<Format4SPT(myCd_CF)>>
		AND Cd_CFDest = <<Format4SPT(myCd_CFDest)>>
		AND Cd_AR = <<Format4SPT(myCd_AR)>>
	ENDTEXT
	&& _CLIPTEXT = cSQL
	oRec = xSQLExec2Obj(cSQL, .T.)
	RETURN oRec
	ELSE
	RETURN .F.
ENDIF


ENDPROC
PROCEDURE xrecar
PARAMETERS myCd_AR
LOCAL oRecAR
LOCAL cSql

IF !IsEmpty(myCd_AR) THEN 
	TEXT TO cSQL TEXTMERGE PRETEXT 7		
		SELECT TOP 1 * FROM AR
		WHERE Cd_AR = <<Format4SPT(myCd_AR)>>
	ENDTEXT
	oRecAR = xSQLExec2Obj(cSQL, .T.)
	RETURN oRecAR
	ELSE
	RETURN .F.
ENDIF
ENDPROC
PROCEDURE Grid.ColCd_AR.stdText1.onvaluechange
Lparameters xOldValue

LOCAL lContinue
LOCAL xAssegnaLotto

** Eseguo le operazioni di default
lContinue = DODEFAULT(xOldValue)

** Se i controlli standard vanno a buon fine ..
IF lContinue THEN 	
	xAssegnaLotto = THISForm.PF.Pggenerale.txtcd_DO.Field.fkrecord.xLTAutoSet
	&& ed il codice articolo è impostato
	IF !IsEmpty(THIS.Value) THEN 		
		
		IF xAssegnaLotto THEN 
		    && 1. Imposto il codice del lotto (se esiste)
			REPLACE Cd_ARLotto WITH THIS.Fkrecord.xCd_ARLottoP IN DoRig
		ENDIF

		&& 2. Valorizzo il prezzo in base alla destinazione merce (se esiste un listino)
		IF !IsEmpty(DoTes.Cd_CFDest) THEN 	
			oListCustom = THIS.Parent.Parent.Parent.xGetPriceByDest(DoTes.Cd_CF, DoTes.Cd_CFDest, THIS.Value)
			IF VARTYPE(oListCustom) = 'O' THEN  
				&& Sostituisco Prezzo/Sconto con i valore impostati nei listini per destinazione (xARListDest)
				IF !IsEmpty(oListCustom.Prezzo) THEN 
					REPLACE PrezzoUnitarioV WITH oListCustom.Prezzo IN DoRig
					REPLACE ScontoRiga WITH oListCustom.Sconto IN DoRig
				ENDIF
			ENDIF
		ENDIF	

	ENDIF
ENDIF
ENDPROC
PROCEDURE Grid.Init
LOCAL oCol1, oCol2
LOCAL myInputMask

&& myInputMask  = THIS.ColQta.InputMask  && "###,###.##" 
myInputMask  = THISFORM.DE.Preferenza.PicSepQta

	** Grid.Init

	** Numero colli / quantità (Custom)
	oCol1 = This.newColumn('xColColli', 'DORig.xColli', 'Colli/Qta', 100)
	oCol1.InputMask = myInputMask
	BINDEVENT(oCol1.StdText1,"IsValid",This.Parent,"xNettoIsValid")

	** Peso lordo
	oCol2 = This.newColumn('xColLordo', 'DORig.xLordo', 'Lordo', 100)
	oCol2.InputMask = myInputMask  
	BINDEVENT(oCol2.StdText1,"IsValid",This.Parent,"xNettoIsValid")

	** Tara 
	oCol3 = This.newColumn('xColTara', 'DORig.xTara', 'Tara', 100)
	oCol3.InputMask = myInputMask  
	BINDEVENT(oCol3.StdText1,"IsValid",This.Parent,"xNettoIsValid")

	** Disabilito l'input della quantità
	THIS.ColQTA.Enabled = .F.
	THIS.ColQTA.Header1.Caption = 'Q.ta/Netto '	

DODEFAULT()


ENDPROC

*======================================================================

*** CLASS / OBJECT: cmdDocASCII (BaseClass: commandbutton, Parent: pgrighe) ***
*** PROPERTIES ***
Top = 274
Left = 564
Height = 37
Width = 95
FontBold = .F.
FontSize = 8
Anchor = 12
Caption = "Importa pesate"
ForeColor = 0,0,255
Name = "cmdDocASCII"

*** METHODS ***
PROCEDURE Click
LOCAL cFileASCII, cBackupFile
LOCAL cCodice, cQta, ccQta, cLotto, lCodArtFound
LOCAL cUm, nQta, nColli, nLordo, nTara, nFatt, nOldFatt, nRptFatt
LOCAL cSQLStmt
LOCAL nRiga
LOCAL xAssegnaLotto

IF (BITAND(ThisForm.Mode, FEDIMODE_EDIT) = 0) AND (BITAND(ThisForm.Mode, FEDIMODE_INS_DUP) = 0) THEN 
   RETURN .F.
ENDIF

xAssegnaLotto = THISForm.PF.Pggenerale.txtcd_DO.Field.fkrecord.xLTAutoSet

cFileASCII = THIS.Parent.xGetAsciiFileName()

IF FILE(cFileASCII) THEN    
    && 
    cBackupFile= THIS.Parent.xGetBackupFileName(cFileASCII)
	&& Controllo ed imposto l'ultimo numero di riga
	nRiga = 0
	SELECT DoRig
	GO BOTTOM	
	IF !EMPTY(Riga) AND !ISNULL(Riga) THEN 
		nRiga = Riga
	ENDIF
	
	&& 	Creo un cursore importando il file ascii (formato CSV)
	CREATE CURSOR Temp (Codice C(20), Qta C(20), Tara C(20), Colli C(20), Lotto C(20)) 
	APPEND FROM (cFileASCII) DELIMITED WITH CHARACTER ";"
	SELECT Temp
	SCAN

		cCodice = ALLTRIM(Temp.Codice)
		cLotto  = ALLTRIM(Temp.Lotto)

		IF !EMPTY(cCodice) THEN 

			&& Prendo i dati importati
			nColli	= VAL(STRTRAN(Temp.Colli, ',', '.'))
			nLordo	= VAL(STRTRAN(Temp.Qta, ',', '.'))
			nTara	= VAL(STRTRAN(Temp.Tara, ',', '.'))
			nQta 	= nLordo - (nColli * nTara)
			
			&& Creo una nuova riga documento
			SELECT DoRig
	   		APPEND BLANK		
	   		&& Imposto i valori di default in base a quantità e codice articolo
	   		THIS.Parent.SetDoRig_Defaults(cCodice, nQta, '') 
			
			&& Imposto numero di riga ed i dati personalizzati
	   		nRiga = nRiga + 1 
	   		REPLACE Riga 		WITH nRiga
	   		
	   		REPLACE xColli		WITH nColli
	   		REPLACE xTara		WITH nTara
	   		REPLACE xLordo		WITH nLordo	   		
	   		IF !IsEmpty(cLotto) THEN 
	   			REPLACE Cd_ARLotto WITH cLotto  
	   		ENDIF

			&& Imposto gli eventuali prezzi da listino per destinazione (xARListDest)
			oListCustom = THIS.Parent.xGetPriceByDest(DoTes.Cd_CF, DoTes.Cd_CFDest, cCodice)
			IF VARTYPE(oListCustom) = 'O' THEN  
				&& Sostituisco Prezzo/Sconto con i valore impostati nei listini per destinazione (xARListDest)
				IF !IsEmpty(oListCustom.Prezzo) THEN 
					REPLACE PrezzoUnitarioV WITH oListCustom.Prezzo IN DoRig
					REPLACE ScontoRiga WITH oListCustom.Sconto IN DoRig
				ENDIF
			ENDIF
			
*!*				&& Imposto l'eventuale lotto automatico
*!*				IF xAssegnaLotto THEN 
*!*					IF !IsEmpty(cCodice) THEN
*!*						oRecAR = THIS.Parent.xRecar(cCodice) 
*!*						IF VARTYPE(oRecAR) = 'O' THEN 
*!*							REPLACE Cd_ARLotto WITH oRecAR.xCd_ARLottoP IN DoRig									
*!*						ENDIF
*!*					ENDIF
*!*				ENDIF
	   		&& Ricalcolo i totali di riga
	   		THIS.Parent.SetDoRig_Formulae()
	   		
	   	ENDIF
   		SELECT Temp
   	ENDSCAN
   	USE IN Temp
	IF cBackupFile <> '' THEN 	 
   		&& Effettuo la copia di backup
   		COPY FILE (cFileASCII) TO (cBackupFile)
   	ENDIF   	
   	&& Cancello il file ascii appena importato
   	DELETE FILE (cFileASCII) 
   	&& Refresh della griglia
   	THIS.Parent.Grid.Refresh   	
   	THIS.Parent.Grid.SetFocus
   	xMessageBox('Importazione pesate completata.')
   ELSE
   xMessageBox('IL FILE ' + cFileASCII + ' non esiste.')
ENDIF
ENDPROC

*======================================================================

