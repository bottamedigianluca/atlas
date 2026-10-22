*** Extracted Visual FoxPro Source Code from ECR_Epson_RT.vcx ***

*** CLASS / OBJECT: ecr_interface_config (BaseClass: form, Parent: ) ***
*** PROPERTIES ***
Height = 471

Width = 561

DoCreate = .T.

hideonclose = .T.

Name = "ecr_interface_config"

timer4ExecAsync.Name = "timer4ExecAsync"

btnOK.Top = 440

btnOK.Left = 408

btnOK.TabIndex = 7

btnOK.Name = "btnOK"

btnEsc.Top = 440

btnEsc.Left = 480

btnEsc.TabIndex = 8

btnEsc.Name = "btnEsc"

LblTitle.Caption = "ECR Configuration - EPSON"

LblTitle.Left = 70

LblTitle.Top = 9

LblTitle.TabIndex = 9

LblTitle.Name = "LblTitle"

shpUpperLine.Top = 42

shpUpperLine.Left = 4

shpUpperLine.Height = 2

shpUpperLine.Width = 550

shpUpperLine.Name = "shpUpperLine"

shpLowerLine.Top = 249

shpLowerLine.Left = 3

shpLowerLine.Height = 2

shpLowerLine.Width = 551

shpLowerLine.Name = "shpLowerLine"

Image.Top = 9

Image.Left = 8

Image.Height = 32

Image.Width = 32

Image.TabIndex = 10

Image.Name = "Image"


*** METHODS ***
PROCEDURE propput

Lparameters cECR_Configuration, cPropName, vPropValue



DO Case

	Case Vartype(vPropValue) = 'C'

		If Atc('"', vPropValue) == 0

			Return cECR_Configuration + cPropName + '="' + Transform(Rtrim(vPropValue)) + '"' + CRLF

		Else

		If Atc("'", vPropValue) == 0

			Return cECR_Configuration + cPropName + "='" + Transform(Rtrim(vPropValue)) + "'" + CRLF

		Else

		If	Atc('[', vPropValue) == 0 And Atc(']', vPropValue) == 0

			Return cECR_Configuration + cPropName + '=[' + Transform(Rtrim(vPropValue)) + ']' + CRLF

		Else

			vPropValue = Strtran(vPropValue, '"', '" + Chr(34) + "')

			Return cECR_Configuration + cPropName + '="' + Transform(Rtrim(vPropValue)) + '"' + CRLF

		EndIf

		EndIf

		EndIf

	Case Vartype(vPropValue) = 'N'

		Return cECR_Configuration + cPropName + '=' + Transform(vPropValue) + CRLF

	Case Vartype(vPropValue) = 'L'

		Return cECR_Configuration + cPropName + '=' + Transform(vPropValue) + CRLF

	Case Vartype(vPropValue) = 'D'

		Return cECR_Configuration + cPropName + '=' + Transform(DToS(vPropValue), '@R {^####/##/##') + '}' + CRLF	

	Otherwise

		Error "Formato non supportato"

		Return cECR_Configuration 

EndCase

ENDPROC

PROCEDURE propget

Lparameters cECR_Configuration, cPropName, vDefaultValue



oApp.RegExpr.IgnoreCase = .T.

oApp.RegExpr.Pattern		= '\s*' + cPropName + '\s*=\s*(.+)\s*'

oMatches = oApp.RegExpr.Execute(cECR_Configuration)

If oMatches.Count > 0

	Return Evaluate(oMatches.Item(0).SubMatches(0))

Else

	Return vDefaultValue

EndIf

ENDPROC

PROCEDURE setfieldsvalue

LPARAMETERS lShowOnly



If lShowOnly

	This.chkSCStory				.ReadOnly = .T.

	This.chkSCPrintToFile 		.ReadOnly = .T.

	This.chkECRAnswer			.ReadOnly = .T.

	This.txtFolderName			.Enabled  = .F.

	This.txtMaskScontrino.Field	.ReadOnly = .T.

	This.txtFolderStory			.Enabled  = .F.

	This.txtMaskStorico.Field	.ReadOnly = .T.

	This.txtFolderAnswer		.Enabled  = .F.

	This.txtMaskAnswer.Field	.ReadOnly = .T.

	This.txtWPos_TimeOut		.Enabled  = .F.

	This.txtWPos_RowTime		.Enabled  = .F.

	This.btnOK					.Visible  = .F.

	This.btnEsc					.Caption  = 'Esci'

EndIf



** Parsing di cECR_Configuration: il formato l'ho scelto io, non ci sono vincoli.

** Nel caso di questa interfaccia demo ogni valore viene scritto su una riga con nome property, segno uguale, espressione VFP

**		SCView			= .T.

**		SCPrintToFile	= .F.

**		FolderName		= "C:\Tmp"



This.chkSCPrintToFile 		.SetValue (This.PropGet(This.cECR_Configuration, 'SCPrintToFile', 	.T.))

This.chkSCStory				.SetValue (This.PropGet(This.cECR_Configuration, 'SCStory', 		.F.))

This.chkECRAnswer			.SetValue (This.PropGet(This.cECR_Configuration, 'ECRAnswer', 		.F.))

This.txtFolderName			.SetValue (This.PropGet(This.cECR_Configuration, 'FolderName', 		"" ))

This.txtFolderStory			.SetValue (This.PropGet(This.cECR_Configuration, 'FolderStory', 	"" ))

This.txtFolderAnswer		.SetValue (This.PropGet(This.cECR_Configuration, 'FolderAnswer', 	"" ))

This.txtMaskScontrino.Field	.SetValue (This.PropGet(This.cECR_Configuration, 'MaskScontrino',	"" ))

This.txtMaskStorico.Field	.SetValue (This.PropGet(This.cECR_Configuration, 'MaskStorico', 	"" ))

This.TxtMaskAnswer.Field	.SetValue (This.PropGet(This.cECR_Configuration, 'MaskAnswer', 		"" ))

This.txtwPos_TimeOut.Field	.SetValue (This.PropGet(This.cECR_Configuration, 'PosTimeout', 		'0' ))

This.txtWPos_RowTime.Field	.SetValue (This.PropGet(This.cECR_Configuration, 'PosRowTime', 		'1'))	



ENDPROC

PROCEDURE Init

Local cEcr_Configuration, lShowOnly



DODEFAULT()



cEcr_Configuration = This.Parameters.Param1

lShowOnly  = This.Parameters.Param2





This.AddProperty('cEcr_Configuration', cEcr_Configuration)



This.SetFieldsValue(lShowOnly)







ENDPROC

PROCEDURE querysave

If This.chkSCPrintToFile.Value = .F.

	This.txtFolderName.SetValue('')

EndIf



If This.chkSCStory.Value = .F.

	This.txtFolderStory.SetValue('')

	This.txtMaskScontrino.Field.setValue('')

EndIf



If This.chkECRAnswer.Value = .F.

	This.txtFolderAnswer.SetValue('')

	This.txtMaskAnswer.Field.setValue('')

ENDIF



Return .T.

ENDPROC

PROCEDURE save

DODEFAULT()



Local cEcr_Configuration



If This.WasConfirmed

	cECR_Configuration = ''

	cECR_Configuration = This.PropPut(cECR_Configuration, 'SCPrintToFile', This.chkSCPrintToFile.Value )

	cECR_Configuration = This.PropPut(cECR_Configuration, 'SCStory', 	   This.chkSCStory.Value )	

	cECR_Configuration = This.PropPut(cECR_Configuration, 'EcrAnswer', 	   This.chkEcrAnswer.Value )

	cECR_Configuration = This.PropPut(cECR_Configuration, 'FolderName',    This.txtFolderName.Value )

	cECR_Configuration = This.PropPut(cECR_Configuration, 'FolderStory',   This.txtFolderStory.Value )

	cECR_Configuration = This.PropPut(cECR_Configuration, 'FolderAnswer',  This.txtFolderAnswer.Value )

	cECR_Configuration = This.PropPut(cECR_Configuration, 'MaskScontrino', This.txtMaskScontrino.Field.Value )	

	cECR_Configuration = This.PropPut(cECR_Configuration, 'MaskStorico',   This.txtMaskStorico.Field.Value )	

	cECR_Configuration = This.PropPut(cECR_Configuration, 'MaskAnswer',    This.txtMaskAnswer.Field.Value )	

	cECR_Configuration = This.PropPut(cECR_Configuration, 'PosTimeout',    This.txtWPos_Timeout.Field.Value )	

	cECR_Configuration = This.PropPut(cECR_Configuration, 'PosRowTime',    This.txtWPos_RowTime.Field.Value )	

	This.cECR_Configuration = cECR_Configuration

EndIf



ENDPROC


*======================================================================

*** CLASS / OBJECT: chkSCStory (BaseClass: checkbox, Parent: ecr_interface_config) ***
*** PROPERTIES ***
Top = 139

Left = 12

Alignment = 0

Caption = "Crea lo storico degli scontrini."

TabIndex = 4

Name = "chkSCStory"


*** METHODS ***
PROCEDURE onvaluechange

Lparameters xOldValue



This.Parent.txtFolderStory.Visible = This.Value





ENDPROC


*======================================================================

*** CLASS / OBJECT: chkSCPrintToFile (BaseClass: checkbox, Parent: ecr_interface_config) ***
*** PROPERTIES ***
Top = 77

Left = 12

Alignment = 0

Caption = "Scrivi lo scontrino su un file ( COMANDI )"

TabIndex = 1

Name = "chkSCPrintToFile"


*** METHODS ***
PROCEDURE onvaluechange

Lparameters xOldValue



This.Parent.txtFolderName.Visible = This.Value





ENDPROC


*======================================================================

*** CLASS / OBJECT: LblMask (BaseClass: label, Parent: ecr_interface_config) ***
*** PROPERTIES ***
FontName = "Courier New"

FontSize = 8

Alignment = 0

BackStyle = 1

Caption = "Variabili"

Height = 144

Left = 305

Top = 276

Width = 247

TabIndex = 11

BackColor = 255,255,128

Name = "LblMask"


*** METHODS ***
PROCEDURE Init

DODEFAULT()

this.Caption = "Scorciatoie disponibili nella Mask" + CRLF + ;

	"'<AAAA>'    : Anno" + CRLF + ;

	"'<MM>'      : Mese" + CRLF + ;

	"'<GG>'      : Giorno" + CRLF + ;

	"'<NUMSC>'   : Id Scontrino" + CRLF + ;

	"'<HHMMSS>'  : Ora Emiss."



ENDPROC


*======================================================================

*** CLASS / OBJECT: TxtWPos_RowTime (BaseClass: container, Parent: ecr_interface_config) ***
*** PROPERTIES ***
Top = 384

Left = 6

Width = 48

Height = 30

TabIndex = 5

ZOrderSet = 25

Name = "TxtWPos_RowTime"

Label.Comment = "3F81D34E-36A2-470F-A362-01429A0C967E"

Label.Caption = "Rigo"

Label.Left = 1

Label.Top = -2

Label.Name = "Label"


*** METHODS ***
PROCEDURE Init

Dodefault()



ft = VARTYPE(This.Field.Value)

IF ft = 'N' THEN 

	IF This.Field.Value < 1

		This.Field.Value = 1

	ENDIF

	ELSE

	This.Field.Value = 1

ENDIF



ENDPROC


*======================================================================

*** CLASS / OBJECT: LblDisattivaAttesa (BaseClass: label, Parent: ecr_interface_config) ***
*** PROPERTIES ***
FontBold = .T.

FontSize = 8

WordWrap = .T.

Alignment = 2

BackStyle = 1

BorderStyle = 1

Caption = ( 'Tempo medio di attesa per uno scontrino.' + CHR(13) + Chr(13) +   'Indicando un valore <= 0 la procedura non attende il file di risposta dalla cassa!!!' + CHR(13) + 'In questo caso il numero scontrino viene assegnato da Arca.')

Height = 93

Left = 60

Top = 276

Visible = .T.

Width = 240

TabIndex = 27

ForeColor = 0,0,255

BackColor = 184,197,254

ZOrderSet = 29

Name = "LblDisattivaAttesa"


*** METHODS ***
PROCEDURE Init

Text To This.ToolTipText NoShow Pretext 7

	La gestione del numero di decimali per prezzo unitario non è accettata da tutti i registratori di cassa.

	Il numero di decimali ammesso non è uguali per tutti i registratori.

EndText



Return DoDefault()



ENDPROC


*======================================================================

*** CLASS / OBJECT: LblAttesaRigo (BaseClass: label, Parent: ecr_interface_config) ***
*** PROPERTIES ***
FontBold = .T.

FontSize = 8

WordWrap = .T.

Alignment = 2

BackStyle = 1

BorderStyle = 1

Caption = "Tempo medio per rigo da sommare al minimo per l'attesa totale."

Height = 36

Left = 60

Top = 384

Visible = .T.

Width = 240

TabIndex = 28

ForeColor = 0,0,255

BackColor = 184,197,254

ZOrderSet = 30

Name = "LblAttesaRigo"


*** METHODS ***
PROCEDURE Init

Text To This.ToolTipText NoShow Pretext 7

	La gestione del numero di decimali per prezzo unitario non è accettata da tutti i registratori di cassa.

	Il numero di decimali ammesso non è uguali per tutti i registratori.

EndText



Return DoDefault()



ENDPROC


*======================================================================

*** CLASS / OBJECT: chkECRAnswer (BaseClass: checkbox, Parent: ecr_interface_config) ***
*** PROPERTIES ***
Top = 194

Left = 12

Alignment = 0

Caption = "Risposta ECR"

TabIndex = 4

Name = "chkECRAnswer"


*** METHODS ***
PROCEDURE onvaluechange

Lparameters xOldValue



This.Parent.txtFolderAnswer.Visible = This.Value



ENDPROC


*======================================================================

*** CLASS / OBJECT: fpmate (BaseClass: container, Parent: ) ***
*** PROPERTIES ***
Name = "fpmate"


*** METHODS ***
PROCEDURE iuistrtran4lcd

LPARAMETERS cString, oVBSconR



cString = STRTRAN(cString, '<DESCRIZIONE>', LEFT(this.xValidDesc(Nevl(oVBSconR.DescrizioneBreve, oVBSconR.Descrizione)), 16))

cString = STRTRAN(cString, '<QTA>', 		STRTRAN(TRAN(oVBSconR.qta, '####'), '.', ','))

cString = STRTRAN(cString, '<UM>', 			lower(NVL(oVBSconR.cd_ARMisura, 'PZ')))

cString = STRTRAN(cString, '<IMPORTO>', 	STRTRAN(TRAN(oVBSconR.PrezzoTotale, '#####.##'), '.', ','))



RETURN cString



ENDPROC

PROCEDURE iuistrtran4prn

LPARAMETERS cString, oVBSconR



LOCAL nImpSconto

LOCAL cQta, cPrezzoUn, cDescSconto, cImpSconto, cRigaSconto

LOCAL cNumReparto



** TECNOBIT Inizio (08.08.2016)

** Nota importante: solitamente le casse accettano solo due decimali per i prezzi unitari. ***

** Il prezzo unitario nella versione base era calcolato dividendo il totale per la quantità ma,

** l'applicazione di sconti di riga può determinare problemi di arrotondamenti con la conseguenza 

** che il totale di riga e di scontrino possono differire da quelli inputati e conseguentemente

** non conciliarsi con le modalità di incasso.

** Orignale:

*!*	cPrezzoUN = This.IuiFormatVal(oVBSconR.PrezzoTotale / oVBSconR.Qta) && ORIGINALE ARCA

** Ad esempio 

** Totale di riga scontato: 10.33, Quantita 4

** cPrezzoUn vale 2.5825 che arrotondato diventa 2.58

** La cassa di conseguenza gestirebbe  2.58 x 4 per un totale di riga di 10.32 

** La differenza (negativa) di un centesimo mancherebbe sul totale di riga 

** e se fosse positiva in alcuni casi impedirebbe la chiusura dello scontrino.

**

** SOLUZIONE:

** Evitare che i calcoli vengano effettuati dalla cassa passando i valori come vengono calcolati da Arca

** - Passare l'importo dello sconto come valore (Calcolato) anzichè percentuale

**   (Indicando nella descrizione la percentuale/formula dello sconto)	

** - Se il prezzo unitario "usa" più di due decimali inviare il totale a corpo omettendo Qta x Prezzo

** -   



** Controllo decimali prezzo unitario

IF ROUND(oVBSconR.PrezzoUnitario, 2) = oVBSconR.PrezzoUnitario THEN 

	** Se il prezzo è utilizza fino a due decimali passo quantità e prezzo unitario

	cQta = This.IuiFormatVal(oVBSconR.qta)

	cPrezzoUN = This.IuiFormatVal(oVBSconR.PrezzoUnitario) 

	ELSE

	** Se il prezzo unitario utilizza più di due decimali utilizzo il totale lordo ( senza l'applicazione dello sconto )

	** e lo passo a corpo (la quantità 1,00 verrà poi tolta in automatico a fine metodo)

	cQta = '1,00'

	&& Calcolo il totale di riga lordo con tutti i decimali

	aValue = oVBSconR.PrezzoUnitario * oVBSconR.Qta

	&& Per riportarlo nel valore da stampare devo arrotondarlo a 2 decimali

	&& ma il risultato non sempre viene arrotondato correttamente da Round()

	&& forse a cause a dell'alto numero di decimali 

	&& (es. 0.315000000*15.0000000=4.725000000) --> 4.72 anzichè 4.73

	&& Per ovviare converto in stringa e abbasso il n. di decimali	

	sValue = (STR(aValue, 15, 4))

	&& Converto in numero 

	aValue = VAL(sValue)

	&& Applico il valore arrotondato

	cPrezzoUN = This.IuiFormatVal(ROUND(aValue, 2))	

	&& cPrezzoUN = This.IuiFormatVal(ROUND(oVBSconR.PrezzoUnitario * oVBSconR.Qta, 2)) 

ENDIF



** Gestione custom reparti

cNumReparto = xDefault(oVBSconR.CD_vbReparto, '01')

*!*	IF oVBSconR.Cd_VBCliente == 'ECOM' THEN

*!*		cNumReparto = PADL(ALLTRIM(STR(VAL(cNumReparto) + 8, 2, 0)), 2, '0') && Reparto + 8 

*!*	ENDIF

** Originale Arca

cString = STRTRAN(cString, '<DESCRIZIONE>', LEFT(this.xValidDesc(Nevl(oVBSconR.DescrizioneBreve, oVBSconR.Descrizione)), 16))

cString = STRTRAN(cString, '<QTA>', 		STRTRAN(cQta, "-", ""))

cString = STRTRAN(cString, '<PREZZO>', 		STRTRAN(cPrezzoUn, "-", ""))

cString = Strtran(cString, '<OPT>', 		xDefault(This.Operatore, '1'))

&& cString = Strtran(cString, '<REP>', 		xDefault(oVBSconR.CD_vbReparto, '01'))

cString = Strtran(cString, '<REP>', 		cNumReparto)

** Fine originale Arca



cRigaSconto = ''

IF !IsEmpty(oVBSconR.ScontoP) THEN 	

	&& Aggiungo una riga con i dati dello sconto

	cRigaSconto = This.cScontoRiga4ECR 

	IF oVBSconR.qta > 0 THEN 			

		nImpSconto = ROUND(oVBSconR.PrezzoUnitario * oVBSconR.Qta, 2) - oVBSconR.PrezzoTotale    && Sconto normale

		cDescSconto = ' SCONTO ' + ALLTRIM(oVBSconR.ScontoP)

		IF AT('+', oVBSconR.ScontoP, 1) = 0 THEN 

			cDescSconto = cDescSconto + ' %'

		ENDIF

		ELSE

		nImpSconto = - (ABS(ROUND(oVBSconR.PrezzoUnitario * oVBSconR.Qta, 2)) - ABS(oVBSconR.PrezzoTotale))  && Sconto su reso (negativo)

		cDescSconto = 'SCONTO' && Su sconti negativi la descrizione viene ignorata ...

	ENDIF

	cImpSconto  = This.IuiFormatVal(nImpSconto)

	cRigaSconto = STRTRAN(cRigaSconto, '<DESCRIZIONE>', LEFT(cDescSconto, 16))

	cRigaSconto = STRTRAN(cRigaSconto, '<OPT>', This.Operatore)

	cRigaSconto = STRTRAN(cRigaSconto, '<REP>', cNumReparto)

	IF oVBSconR.qta > 0 THEN 			

		cRigaSconto = STRTRAN(cRigaSconto, '<IMPORTO>', 	STRTRAN(cImpSconto, "-", "")) && Sconto normale

		ELSE

		cRigaSconto = STRTRAN(cRigaSconto, '<IMPORTO>', 	cImpSconto) && Sconto su reso

	ENDIF

ENDIF

IF !IsEmpty(cRigaSconto) THEN 

	cString = cString + CHR(13)+CHR(10)+ cRigaSconto

ENDIF



*!*	&& IF PemStatus(oVBSconR, "Omaggio" ,5) THEN 

*!*	IF oApp.ExeInfo.BuildNo >= 6114 THEN 

*!*		&& Omaggio (a partire dalla release 2/2021 (Build 6114): 02/09/2021)

*!*		IF oVBSconR.Omaggio THEN 

*!*			

*!*			cPrezzo = This.IuiFormatVal(oVBSconR.PrezzoTotale) 

*!*			

*!*			aStr = "printRecItemAdjustment|<OPT>|<DESCRIZIONE>|11|<PREZZO>|<REP>|1"

*!*			aStr = STRTRAN(aStr, '<DESCRIZIONE>'	, 'OMAGGIO')

*!*			aStr = STRTRAN(aStr, '<PREZZO>'			, STRTRAN(cPrezzo, "-", ""))

*!*			aStr = Strtran(aStr, '<OPT>'			, xDefault(This.Operatore, '1'))

*!*			aStr = Strtran(aStr, '<REP>'			, cNumReparto)

*!*			

*!*			cString = cString + CHR(13)+CHR(10)+ aStr

*!*			

*!*		ENDIF

*!*	ENDIF 



** TECNOBIT fine



*

* Se invio nel comando la stringa QTY=1.00 ogni vendita sarà di due righe. Es : 

* --------------------------

* 1.00 x 11.00

* BORSETTA TESSUTO   11.00

* --------------------------

* Se elimino la parte con QTY=1.00 resta solo il secondo rigo quindi :

*



&& cString = STRTRAN(cString, 'QTY=1.00,', '')

RETURN cString + CHR(13)+CHR(10)

ENDPROC

PROCEDURE iuicheckexistdir

LPARAMETERS cString2Check



Local N, cDir2Check

N = 1

cString2Check = UPPER(ALLTRIM(ADDBS(cString2Check)))

&& TECNOBIT

&& Controllo se è un percorso di rete 

IF LEFT(cString2Check, 2) = '\\'  THEN && E' un percorso assoluto \\indirizzo\1^dir\

   N = 4 && Sposto l'inizio ricerca delle sottocartelle dal 4° carattere (oltre \\ iniziale)

ENDIF

nPosBar = At('\', cString2Check, N)

&& FINE Tecnobit



&& nPosBar = At('\', cString2Check, 1) && Originale

Do While nPosBar > 0

	cDir2Check = Left(cString2Check, nPosBar - 1)

	If !Directory(cDir2Check)

		MKDIR (cDir2Check)

		If !Directory(cDir2Check)

			xMESSAGEBOX('Impossibile creare la cartella ' + cDir2Check)

			Return .F.

		Endif

	Endif

	N = N + 1

	nPosBar = At('\', cString2Check, N)

Enddo

Return .T.



ENDPROC

PROCEDURE iuistrtran4story

LPARAMETERS cNameMask, oVBSconT



cNameMask = Strtran(cNameMask, '<AAAA>'	 , This.cRefYear) 	&& Padl(Year (Date()), 4, '0'))

cNameMask = Strtran(cNameMask, '<MM>'	 , This.cRefMonth) 	&& Padl(Month(Date()), 2, '0'))

cNameMask = Strtran(cNameMask, '<GG>'	 , This.cRefDay) 	&& Padl(Day  (Date()), 2, '0'))

cNameMask = STRTRAN(cNameMask, '<HHMMSS>', This.cRefTS) 	&& CHRTRAN(TTOC(oVBSconT.dataorareg, 2), ":", ""))

cNameMask = STRTRAN(cNameMask, '<NUMSC>' , This.cRefSc) 	&& PADL(INT(oVBSconT.id_VBScont), 7, '0'))



**

** Controllo l'esistenza delle cartelle ed eventualmente le creo.

**

If !This.iuiCheckExistDir(Justpath(cNameMask))

	Return .F.

Endif



RETURN cNameMask



ENDPROC

PROCEDURE propget

Lparameters cECR_Configuration, cPropName, vDefaultValue



oApp.RegExpr.IgnoreCase = .T.

oApp.RegExpr.Pattern		= '\s*' + cPropName + '\s*=\s*(.+)\s*'

oMatches = oApp.RegExpr.Execute(cECR_Configuration)

If oMatches.Count > 0

	Return Evaluate(oMatches.Item(0).SubMatches(0))

Else

	Return vDefaultValue

EndIf

ENDPROC

PROCEDURE propput

Lparameters cECR_Configuration, cPropName, vPropValue



DO Case

	Case Vartype(vPropValue) = 'C'

		If Atc('"', vPropValue) == 0

			Return cECR_Configuration + cPropName + '="' + Transform(Rtrim(vPropValue)) + '"' + CRLF

		Else

		If Atc("'", vPropValue) == 0

			Return cECR_Configuration + cPropName + "='" + Transform(Rtrim(vPropValue)) + "'" + CRLF

		Else

		If	Atc('[', vPropValue) == 0 And Atc(']', vPropValue) == 0

			Return cECR_Configuration + cPropName + '=[' + Transform(Rtrim(vPropValue)) + ']' + CRLF

		Else

			vPropValue = Strtran(vPropValue, '"', '" + Chr(34) + "')

			Return cECR_Configuration + cPropName + '="' + Transform(Rtrim(vPropValue)) + '"' + CRLF

		EndIf

		EndIf

		EndIf

	Case Vartype(vPropValue) = 'N'

		Return cECR_Configuration + cPropName + '=' + Transform(vPropValue) + CRLF

	Case Vartype(vPropValue) = 'L'

		Return cECR_Configuration + cPropName + '=' + Transform(vPropValue) + CRLF

	Case Vartype(vPropValue) = 'D'

		Return cECR_Configuration + cPropName + '=' + Transform(DToS(vPropValue), '@R {^####/##/##') + '}' + CRLF	

	Otherwise

		Error "Formato non supportato"

		Return cECR_Configuration 

EndCase

ENDPROC

PROCEDURE iuiscquerystory

Lparameters oVbCausale, oVBSconT, oColVBSconR, oColVBSconP



LOCAL lStory



lStory = .T.



IF lStory AND VARTYPE(oVBCausale) = 'O'

	** EFFETTUO IL CONTROLLO SULLA CAUSALE

	lStory = !oVBCausale.NonInviaScontrino

* ff *		DO case

* ff *			CASE INLIST(oVBCausale.In, 'VE ', 'VEN')

* ff *				lContinue = .T.

* ff *			OTHERWISE

* ff *				lContinue = .F.

* ff *		ENDCASE

ENDIF



IF lStory AND VARTYPE(oVBSconT) = 'O'

	** EFFETTUO IL CONTROLLO SULLA TESTA DEL DOCUMENTO

ENDIF



IF lStory AND VARTYPE(oColVBSconR) = 'O'

	** EFFETTUO IL CONTROLLO SULLE RIGHE DEL DOCUMENTO

ENDIF



IF lStory AND VARTYPE(oColVBSconP) = 'O'

	** EFFETTUO IL CONTROLLO SUI PAGAMENTI.

ENDIF



RETURN lStory 



ENDPROC

PROCEDURE xvaliddesc

PARAMETERS cDesc



cDesc = STRTRAN(cDesc, '"', ' ')  			&& TECNOBIT: Doppio apice è un delimitatore di stringa

cDesc = STRTRAN(cDesc, "'", ' ')  			&& TECNOBIT: Apice singolo è un delimitatore di stringa

cDesc = STRTRAN(cDesc, '/', '-')  			&& 

cDesc = STRTRAN(cDesc, 'TOTALE', 'TOT.')  	&& TECNOBIT: Le casse DITRON non accettano la scitta TOTALE nella descrizione prodotto

cDesc = STRTRAN(cDesc, CHR(10), '')      	&& TECNOBIT: tolgo il carattere Line feed (10 o 0D in esadecimale)

cDesc = ALLTRIM(cDesc)      				&& TECNOBIT: Tolgo gli spazi eccedenti 



RETURN cDesc

ENDPROC

PROCEDURE xtryscemit

LParameters cStorico, oVBSconT

LOCAL bCompletato

LOCAL cNomeScontrino

LOCAL nTentativi 

LOCAL i



cNomeScontrino = This.xTran4ScName(This.cNameMask, oVBSconT)



bCompletato = .F.

nTentativi = 10

i = 1

DO WHILE !bCompletato

	TRY

		WAIT "Creazione scontrino (" + STR(i,2,0)+")" WINDOWS NOWAIT



		IF i >= 5 THEN 		

			&& A partire dal quinto tentativo, prima di creare lo scontrino finale, cerco di cancellare 

			&& l'eventuale file di scontrino esistente (potrebbe essere la causa del blocco).

			&& Tra l'altro, eventualmente conterrebbe solo il comando di visualizzazione per il display cliente,		

			&& dell'ultimo articolo/comando  

			IF FILE(cNomeScontrino) THEN && Era This.cPathTo

				DELETE FILE(cNomeScontrino) RECYCLE && Era This.cPathTo

			ENDIF

		ENDIF

		

		IF this.iuiSCQueryEmit(This.oVBCausale)

			&& Se esiste il file dello storico lo copio per la stampa 

			bCopy = .F.

			IF cStorico <> '' THEN 

			   IF FILE(cStorico) THEN 

			      bCopy = .T.

			   ENDIF

			ENDIF

			IF bCopy = .T. THEN

				&& COPY FILE (cStorico) TO (This.cPathTO) 

				COPY FILE (cStorico) TO (cNomeScontrino) && Dopo che è stato creato lo copio per procedere alla stampa

			ELSE

				&& Altrimenti,

				&&   1. Scrivo in un file di appoggio (<nomeSc> + '.tmp') per evitare che venga tentata la stampa prima della creazione completa

				&&   2. Copio il file temporaneo e completo (COPY FILE <NomeSc> + '.tmp ' <NomeSc>) per permettere la stampa

				&&   3. Cancello il file temporaneo (DELETE FILE <NomeSc> + '.tmp')

				STRTOFILE(cScontrino, cNomeScontrino + '.tmp')        	&& 1

				COPY FILE (cNomeScontrino + '.tmp') TO (cNomeScontrino) && 2

				DELETE FILE (cNomeScontrino + '.tmp')					&& 3

			ENDIF

		ENDIF

		bCompletato = .T.

	CATCH TO oException

	    bCompletato = .F.

	    && WAIT "Errore" WINDOW TIMEOUT 1

	FINALLY

 		IF !bCompletato THEN 

	 		i = i + 1

	 		IF i > nTentativi THEN 

	 		   bCompletato = .T.

	 		ENDIF

	 	ENDIF

	ENDTRY

ENDDO

WAIT CLEAR



RETURN bCompletato 

ENDPROC

PROCEDURE xtran4scname

LPARAMETERS cNameMask, oVBSconT



cNameMask = Strtran(cNameMask, '<AAAA>', This.cRefYear) 	&& Padl(Year (Date()), 4, '0'))

cNameMask = Strtran(cNameMask, '<MM>',   This.cRefMonth)	&& Padl(Month(Date()), 2, '0'))

cNameMask = Strtran(cNameMask, '<GG>',   This.cRefDay) 		&& Padl(Day  (Date()), 2, '0'))

IF VARTYPE(oVBSconT) = 'O' THEN 

	cNameMask = STRTRAN(cNameMask, '<HHMMSS>', This.cRefTS)	&& CHRTRAN(TTOC(oVBSconT.dataorareg, 2), ":", ""))

	cNameMask = STRTRAN(cNameMask, '<NUMSC>',  This.cRefSc)	&& PADL(INT(oVBSconT.id_VBScont), 7, '0'))

	ELSE

	cNameMask = STRTRAN(cNameMask, '<HHMMSS>', 'LCD')

	cNameMask = STRTRAN(cNameMask, '<NUMSC>',  '')

ENDIF



**

** Controllo l'esistenza delle cartelle ed eventualmente le creo.

**

If !This.iuiCheckExistDir(Justpath(cNameMask))

	Return .F.

Endif



RETURN cNameMask

ENDPROC

PROCEDURE iuiformatdata

Lparameters dData

dTemp = Transform(Dtos(dData))

dOut  = RIGHT(dTemp, 2) + SUBSTR(dTemp, 5, 2) + LEFT(dTemp, 4)

Return dOut

ENDPROC

PROCEDURE drvgeterror

Lparameters cFileResult

&& Restituisce l'eventuale messaggio di errore 

LOCAL ErrorDesc



cFileResult = ALLTRIM(cFileResult)

ErrorDesc = '' 



IF cFileResult <> '' THEN 

	ErrorDesc = 'File di risposta non trovato.'

	IF FILE(cFileResult) THEN 

		RTResult 	= FILETOSTR(cFileResult)

		ErrorDesc 	= Rex_ExtractToken(RTResult, 'Description=(.*?);', .T.)

	ENDIF

ENDIF



Return ErrorDesc 



ENDPROC

PROCEDURE drvresultok

Lparameters cFileResult

&& Indica se il risultato è ok 

LOCAL IsOk



cFileResult = ALLTRIM(cFileResult)

IsOk = .F.



IF cFileResult <> '' THEN 

	IF FILE(cFileResult) THEN 		

		RTResult 	= FILETOSTR(cFileResult)

		ResultMsg 	= Rex_ExtractToken(RTResult, 'Result=(.*?)\|', .T.)

		IF UPPER(ResultMsg) = 'OK' THEN 

			IsOk = .T.		

		ENDIF

	ENDIF

ENDIF



Return IsOk



ENDPROC

PROCEDURE vbscon_numero

LParameters cFileResult as String



Local cNumber As String



cFileResult = ALLTRIM(cFileResult)

cNumber = '0' 



IF cFileResult <> '' THEN 

	IF FILE(cFileResult) THEN 

		RTResult 	= FILETOSTR(cFileResult)

		cNumber 	= Rex_ExtractToken(RTResult, 'ZDocNum=(.*)', .T.)

		cNumber		= STRTRAN(cNumber, '-', '')	&& Tolgo il carattere '-'

	ENDIF

ENDIF



If Empty(Val(cNumber))



	Text To cMsg Noshow Textmerge Pretext 2

		La risposta del driver non è completa.

		Non sarà possibile recuperare il numero dello scontrino.

	EndText



	xMessageBox(Thisform.TB_(,'715C5E5B-28ED-4119-A1F7-D694E9331DAC', cMsg))



EndIf



cMsg = 'Scontrino n° %1! inviato con successo alla cassa.'



*!*	Do Case

*!*	case cOperazione	= 'Scontrino'

*!*		cMsg = 'Scontrino n° %1! inviato con successo alla cassa.'



*!*	case cOperazione	= 'ANNULLO'

*!*		cMsg = 'Scontrino n° %1! annullato con successo.'

*!*		

*!*	endcase



&& xMessageBox(Thisform.TB_(,'EA92F3C6-0143-4F8F-AB5A-1C74D0403FF6', cMsg, Transform(cNumber, '@R XXXX-XXXX') ))



Return Val(cNumber)

   



ENDPROC

PROCEDURE ariecreditconfiguration

Lparameters cECR_Configuration, lShowOnly



Local oCfgEditForm



cECR_Configuration = Nvl(cECR_Configuration, '')



oCfgEditForm 		 = RunGeneric(This.ClassLibrary, Thisform, 'ECR_Interface_Config', cEcr_Configuration, lShowOnly) 

oCfgEditForm.Show(1)



cECR_Configuration = oCfgEditForm.cECR_Configuration 



oCfgEditForm.Release()



Return cECR_Configuration







ENDPROC

PROCEDURE ariecrdisconnect

Lparameters oVBCassa, oOperatore



DODEFAULT(oVBCassa, oOperatore)

ENDPROC

PROCEDURE ariscemit

Lparameters oVBSconT, oColVBSconR, oColVBSconP



LOCAL cScontrino

LOCAL cTipoOperazione

LOCAL lScontrinoParlante



cScontrino = ''



&& Tecnobit (1)

LOCAL cStorico

LOCAL nResult

cStorico = ''

nResult = 0



This.cRefYear	= Padl(Year (Date()), 4, '0')

This.cRefMonth	= Padl(Month(Date()), 2, '0')

This.cRefDay	= Padl(Day  (Date()), 2, '0')

This.cRefTS		= CHRTRAN(TTOC(oVBSconT.dataorareg, 2), ":", "")

This.cRefSc		= PADL(INT(oVBSconT.id_VBScont), 7, '0')



cTipoOperazione = This.oVBCausale.Operazione && Vendita, Reso, Annullo



cScontrino = 'printerFiscalReceipt' + CHR(13) + CHR(10)

cScontrino = cScontrino + 'Printer|1' + CHR(13) + CHR(10) 



lExistsx=pemstatus(oVBSconT, "xCodFiscale" ,5)



lScontrinoParlante = .F.

xCF = '' 

IF lExistsx THEN 

 	xCF = UPPER(ALLTRIM(NVL(oVBSconT.xCodFiscale, ''))) 

 	IF !IsEmpty(xCF) THEN 	    

 	    IF LEN(xCF) = 16 THEN  && Codice fiscale

 		   cScontrino = cScontrino + 'directIO|opCodFiscale|' +this.Operatore + '|' +xCF + CHR(13)+CHR(10)

 		   lScontrinoParlante = .T.

 		ENDIF

 	    IF LEN(xCF) = 11 THEN  && Partita IVA

 		   cScontrino = cScontrino + 'directIO|opPartitaIVA|' +this.Operatore + '|' + xCF + CHR(13)+CHR(10)

 		   lScontrinoParlante = .T.

 		ENDIF 		

 	ENDIF

ENDIF 

&& Fine tecnobit (1)



IF INLIST(cTipoOperazione, 'R', 'A') Then 

	&& Estremi per reso/Annullo

	

	IF cTipoOperazione = 'R' THEN   && Reso

		cString = this.cResoReq4ECR

	ENDIF

	IF cTipoOperazione = 'A' THEN   && Annullo

		cString = this.cAnnulloReq4ECR

	ENDIF

	cString = STRTRAN(cString, '<NUMCH>'	,Left 				(oVBSconT.Reso_NumeroRT, 4))	&& Numero chiusura

	cString = STRTRAN(cString, '<NUMSC>'	,Right				(oVBSconT.Reso_NumeroRT, 4))	&& Numero scontrino

	cString = STRTRAN(cString, '<DATASC>'	,This.iuiformatdata  (oVBSconT.Reso_DataOraReg))	&& Data scontrino origine

	cString = STRTRAN(cString, '<MATRICOLA>',Alltrim		 (oVBSconT.Reso_MatricolaCassa))	&& Matricola ECR Origine

	cString = STRTRAN(cString, '<OPT>'		,xDefault		 		  (This.Operatore, '1'))	&& Operatore



	cScontrino = cScontrino + cString + CHR(13) + CHR(10) 



ENDIF



IF cTipoOperazione != 'A' THEN   && Annullo

	&& Corpo documento

	FOR EACH oVBSconR IN oColVBSconr

		IF cTipoOperazione = 'R' THEN 

			cScontrino = cScontrino + this.iuistrtran4prn(this.cReso4ECR, oVBSconR)	&& Reso

			ELSE

			cScontrino = cScontrino + this.iuistrtran4prn(this.cVend4ECR, oVBSconR)	&& Vendita

		ENDIF

	ENDFOR

ENDIF



IF !INLIST(cTipoOperazione, 'R', 'A') Then 

	IF oVBSconT.ImportoSconto > 0 THEN

		cString4Sco = STRTRAN(this.cSconto4ECR, '<IMPORTO>', this.iuiFormatVal(oVBSconT.ImportoSconto))

		cString4Sco = STRTRAN(cString4Sco, '<OPT>', this.Operatore)

		cScontrino = cScontrino + cString4Sco

	ENDIF

ENDIF 



IF !lScontrinoParlante THEN 

	cCodiceLotteria	= Iif(IsEmpty(oVBSconT.CodiceLotteria),  '', Alltrim(oVBSconT.CodiceLotteria))

	IF !IsEmpty(cCodiceLotteria) AND IsEmpty(xCF) THEN  

		cString4Sco = STRTRAN(this.cLottery4ECR, '<LOTTERYID>', cCodiceLotteria)

		cString4Sco = STRTRAN(cString4Sco, '<OPT>', this.Operatore)

		cScontrino = cScontrino + cString4Sco

	ENDIF 

ENDIF



&& Sconto a pagare (OMAGGI)

IF oVBSconT.NonRiscossoOmaggi > 0 THEN 

	cString4pag = STRTRAN(this.cScontoAPagare4ECR, '<IMPORTO>', this.iuiFormatVal(oVBSconT.NonRiscossoOmaggi))

	cString4pag = STRTRAN(cString4pag, '<OPT>', This.Operatore)

	cScontrino = cScontrino + cString4pag

ENDIF

cPagContante = ''

FOR EACH oVBSconP IN oColVBSconP 

	DO case

	CASE oVBSconP.TipoPag = 'C' 

		nImpCash = oVBSconP.Importo

		IF !IsEmpty(nImpCash) THEN 

		    IF ABS(ABS(oVBSconT.ImportoPagato) - ABS(oVBSconP.Importo)) < 0.03 THEN 		

			   && Arrotondamenti 1 o 2 centesimi

			   && Se è stato indicato l'importo arrotondato del contante, 

			   && è l'unica forma di pagamento ed è arrotondato per difetto

			   && invio un importo pari a 0 in modo che la cassa provveda autonomamente 

			   nImpCash = 0

		    ENDIF

			cString4pag = STRTRAN(this.cCassa4ECR, '<IMPORTO>', this.iuiFormatVal(ABS(nImpCash)))

			cString4pag = STRTRAN(cString4pag, '<OPT>', This.Operatore)

			&& cScontrino = cScontrino + cString4pag

			cPagContante = cString4pag

		ENDIF

	CASE oVBSconP.TipoPag = 'P'

		cString4pag = STRTRAN(this.cPos4ECR, '<IMPORTO>', this.iuiFormatVal(ABS(oVBSconP.Importo)))

		cString4pag = STRTRAN(cString4pag, '<OPT>', This.Operatore)

		cScontrino = cScontrino + cString4pag

	CASE oVBSconP.TipoPag = 'K'

		cString4pag = STRTRAN(this.cCarteDiCredito4ECR, '<IMPORTO>', this.iuiFormatVal(ABS(oVBSconP.Importo)))

		cString4pag = STRTRAN(cString4pag, '<OPT>', This.Operatore)

		cScontrino = cScontrino + cString4pag

	CASE oVBSconP.TipoPag = 'A'

		cString4pag = STRTRAN(this.cAssegni4ECR, '<IMPORTO>', this.iuiFormatVal(ABS(oVBSconP.Importo)))

		cString4pag = STRTRAN(cString4pag, '<OPT>', This.Operatore)

		cScontrino = cScontrino + cString4pag

	CASE oVBSconP.TipoPag = 'T'

		cString4pag = STRTRAN(this.cTicket4ECR, '<IMPORTO>', this.iuiFormatVal(ABS(oVBSconP.Importo)))

		cString4pag = STRTRAN(cString4pag, '<OPT>', This.Operatore)

		cScontrino = cScontrino + cString4pag

	CASE oVBSconP.TipoPag = 'B'

		cString4pag = STRTRAN(this.cBuoni4ECR, '<IMPORTO>', this.iuiFormatVal(ABS(oVBSconP.Importo)))

		cString4pag = STRTRAN(cString4pag, '<OPT>', This.Operatore)

		cScontrino = cScontrino + cString4pag

	CASE oVBSconP.TipoPag = 'N'

		cString4pag = STRTRAN(this.cNonRiscossoBeni4ECR, '<IMPORTO>', this.iuiFormatVal(ABS(oVBSconP.Importo)))

		cString4pag = STRTRAN(cString4pag, '<OPT>', This.Operatore)

		cScontrino = cScontrino + cString4pag

	CASE oVBSconP.TipoPag = 'S'

		cString4pag = STRTRAN(this.cNonRiscossoServizi4ECR, '<IMPORTO>', this.iuiFormatVal(ABS(oVBSconP.Importo)))

		cString4pag = STRTRAN(cString4pag, '<OPT>', This.Operatore)

		cScontrino = cScontrino + cString4pag

	CASE oVBSconP.TipoPag = 'F'

		cString4pag = STRTRAN(this.cNonRiscossoFatture4ECR, '<IMPORTO>', this.iuiFormatVal(ABS(oVBSconP.Importo)))

		cString4pag = STRTRAN(cString4pag, '<OPT>', This.Operatore)

		cScontrino = cScontrino + cString4pag



	ENDCASE

ENDFOR

IF !IsEmpty(cPagContante) THEN 

   && Metto il Tender contate dopo tutti gli altri Tender. 

   && Necessario solo dovendo gestire il resto (21.12.2021)

   cScontrino = cScontrino + cPagContante 

ENDIF



IF this.iuiSCQueryStory(This.oVBCausale)

	cStorico = This.iuistrtran4story(This.cHistoryMask, oVBSconT)	

	STRTOFILE(cScontrino, cStorico)

endif



nResult = THIS.xTryScEmit(cStorico, oVBSconT)



IF nResult THEN 

	cFileResult = This.xTran4ScName(This.cResultMask, oVBSconT)



	lAttendiRisposta = (ALLTRIM(cFileResult) <> '')	

	If lAttendiRisposta 

		nRows = Alines(vRow, cScontrino) && Numero di linee del file scontrino

		

		&& Tempo di attesa totale: Base + Tempo in base alle righe scontrino 

		nTotalDelay = This.nPosTimeout + nRows * Iif(This.nPosRowTime < 1, 1, This.nPosRowTime) 



		lContinue = .T.



		** Attesa scontrino OK o errore di trasmissione/fine_carta :::::::::::::::::::::::::::::::::::::::::::::::::

		Do While lContinue			

			tECRInizio = Datetime()

			WAIT 'Controllo esito scontrino' WINDOW TIMEOUT This.nPosTimeout

			** Attesa trasmissione e stampa scontrino -------------------------------------------------------------

			Do While	.T.					

				lTimeOut	 = .F.

				lScontrinoOK = .F.

				lErroreGenerico = .F.

				

				If 	File(cFileResult) && C'è il file del risultato						

					If !This.drvResultOK(cFileResult) 	

						lErroreGenerico = .T. && Contiene un errore

						Else

						lScontrinoOK = .T.

					Endif

					Exit && Esco dal loop perchè la risposta è arrivata

	

				Endif

				If (Datetime() - tECRInizio) > nTotalDelay Then && Tempo di attesa terminato

					lTimeOut = .T.

					Exit

				Endif

				

				Sleep (500)	&& Evita di fare un ciclo troppo impegnativo mandando la CPU al 100%

				

			Enddo

			&& Fine Attesa trasmissione e stampa scontrino 



			lContinue = .F.		

			

			if !lScontrinoOK Then 

				&& Controllo quali errori si sono verificati

				Do Case



					Case lTimeOut		&& Errore TimeOut: Chiedo se si desidera attendere nuovamente	

						Wait Clear

						Text To cMess Noshow Pretext 2

							Tempo di attesa per la cassa superato.

							Vuoi attendere un altro ciclo di %1! secondi ?

						endtext



						If xMessageBox(Thisform.TB_(,'CB17DA5C-FFC3-45F0-9AAC-A3A2A388E7C1', cMess, Transform(nTotalDelay, '####')), 4+32 ) = 6		&& Nuovo ID

							lContinue = .T.

						Endif



					Otherwise			&& Errore Generico

						Wait Clear

						Text To cMess Noshow Pretext 2

							Il Driver ha rilevato un errore.

							%2!

							Vuoi attendere un altro ciclo di %1! secondi ?

						endtext



						If xMessageBox(Thisform.TB_(,'4057C249-C685-4F0D-841D-A3E19D13F71C', cMess, Transform(nTotalDelay, '####'), This.drvGetError(cFileResult)), 4+32 ) = 6		&& Nuovo ID

							lContinue = .T.

						Endif

						

				Endcase

				&& Fine Case Errori con richiesta ulteriore attesa >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

			EndIf



		enddo

		&& Fine Attesa scontrino OK o errore di trasmissione/fine_carta :::::::::::::::::::::::::::::::::::::::::::::::::



		** Case Errori finale ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

		Do Case

			Case lScontrinoOK

				Do Case

				Case 	This.oVBCausale.Operazione = 'A'	

						Wait Clear

						nScon_Numero = This.VBScon_Numero(cFileResult)	

						Return nScon_Numero 

				

				Case 	File(cFileResult)

						Wait Clear

						nScon_Numero = This.VBScon_Numero(cFileResult)

						Return nScon_Numero 

				Otherwise

						** Aggiorna il log con l'errore

						xMessageBox(Thisform.TB_(,'58DAB4C0-1459-4318-A4E7-2CCCE95B6C1E', 'Manca la risposta del driver, non è possibile recuperare il numero dello scontrino.'))



				Endcase





			Case lTimeOut		

				Text To cMess Noshow Pretext 2

					Tempo di attesa per la cassa superato.

				EndText

				** Aggiorna il log con l'errore

				Text To cMess Noshow Textmerge Pretext 2

					Manca la risposta del driver, non è possibile recuperare il numero dello scontrino.

				endtext

		

				xMessageBox(Thisform.TB_(,'0A7001C5-C844-40BA-AFF2-3DC7785176E3', cMess))



			otherwise

				If lErroreGenerico Then					&& <-- Il driver ha risposto nei tempi giusti, ma con un errore

					Text To cMess Noshow Pretext 2

						Il Driver ha restituito un errore di comunicazione con la cassa.

						Sarà impossibile recuperare il numero dello scontrino.

						-----------------------------------

						Errore tornato dal driver:

						%1!

					endtext



					xMessageBox(Thisform.TB_(,'11601F56-DE4A-40F3-A5AB-D5E2E9983D68', cMess, This.drvGetError(cFileResult)))



				Endif										&& <-- Il driver ha risposto nei tempi giusti con l'immagine dello scontrino



		endcase		

		** Fine Case Errori finale ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^



	Endif && lAttendiRisposta



ENDIF



RETURN 0 && nResult



ENDPROC

PROCEDURE ariscabort



STRTOFILE(this.cAnnullaScontrino4LCD, This.cNameLCD)



DODEFAULT()

ENDPROC

PROCEDURE ariscsubtot

Lparameters nQta, nTot, oColVBSconR



LOCAL cString2Send

LOCAL cQta, cImp



cQta = STRTRAN(PADL(TRAN(nQta, '####'), 8, ' ' ), '.', ',') && Virgola come separatore decimale 

cImp = STRTRAN(TRAN(nTot, '#####.##'), '.', ',') && Virgola come separatore decimale 



cString2Send = STRTRAN(this.cSubt4LCD, '<QTA>', cQta)



cString2Send = STRTRAN(cString2Send, '<IMPORTO>', cImp)



STRTOFILE(cString2Send, This.cNameLCD) && This.cPathTO)



ENDPROC

PROCEDURE ariscrowdone

Lparameters oVBSconR



LOCAL cString4File



DO case

case oVBSconR.Qta > 0

	cString4File = this.iuistrtran4lcd(this.cVend4LCD, oVBSconR)

	STRTOFILE(cString4File, This.cNameLCD)

case oVBSconR.Qta < 0

	cString4File = this.iuistrtran4lcd(this.cReso4LCD, oVBSconR)

	STRTOFILE(cString4File, This.cNameLCD)

ENDCASE		



ENDPROC

PROCEDURE ariscinit

Lparameters oOperatore, oVBCausale



DODEFAULT(oOperatore, oVBCausale)



This.AddProperty('oVBCausale' ,  oVBCausale)



cString = This.cBlankString + Chr(13)+ Chr(10) + This.cStartString + Chr(13)+ Chr(10)



Strtofile(cString, This.cNameLCD)



IF !this.iuiSCQueryEmit(oVBCausale)

	xMessageBox("Lo scontrino NON SARA' INVIATO ALLA CASSA")

ENDIF



ENDPROC

PROCEDURE ariecrconnect

Lparameters oVBCassa, oOperatore

Local cMess1, cMess2



this.addproperty('Operatore', ALLTRIM(TRANSFORM(oOperatore.NumeroOperatore, "##")))



this.Operatore = IIF(!ISDIGIT(THIS.OPERATORE) OR !(This.Operatore == '0'), '1', THIS.OPERATORE)

IF this.Operatore = '0' then

	this.Operatore = '1' 

Endif



Local CSEP, CSTRING, COPE, CREP

Local cNameMask, cHistoryMask, cResultMask

LOCAL lEcrAnswer

LOCAL nPosTimeout, nPosRowTime

Local cBeep



#Define _EOL_ Chr(13)+Chr(10)

CSEP = '|'

COPE = '<OPT>'	&& '1'

CREP = '<REP>'	&& '1'

cBeep = "BEEP"



This.AddProperty('cRefYear'	, '2021')

This.AddProperty('cRefMonth', '01')

This.AddProperty('cRefDay'	, '01')

This.AddProperty('cRefTS'	, '115900')

This.AddProperty('cRefSc'	, '0000')



** THIS.cPathTo			Cartella scontrini

cPathScontrino = This.PropGet(OVBCassa.ECR_Configuration, 'FolderName', Addbs(OAPP.HomeDir) + 'Epson')

This.AddProperty('cPathTo' ,  cPathScontrino )

** Controllo l'esistenza delle cartelle ed eventualmente le creo.

If !This.iuiCheckExistDir(Justpath(This.cPathTo))

	Return .F.

ENDIF

** THIS.cNameMask		Mask nome scontrino (completa di percorso)

cNameMask = This.PropGet(OVBCassa.ECR_Configuration, 'MaskScontrino', 'SCO-<NUMSC>-<HHMMSS>.txt')

This.AddProperty('cNameMask', ADDBS(This.cPathTo) + cNameMask)



** THIS.cAnswerFolder	Cartella risposta driver

cAnswerFolder   = This.PropGet(OVBCassa.ECR_Configuration, 'FolderAnswer', '')

This.AddProperty('cAnswerFolder', cAnswerFolder)



** THIS.cStoryTo		Cartella base storico scontrini

cFolderStory   = This.PropGet(OVBCassa.ECR_Configuration, 'FolderStory', Addbs(OAPP.HomeDir) + 'FpMate\Story')

This.AddProperty('cStoryTo', cFolderStory)

**

** Controllo l'esistenza delle cartelle ed eventualmente le creo.

**

If !This.iuiCheckExistDir(Justpath(cFolderStory))

	Return .F.

Endif

** THIS.cHistoryMask	Mask PATH/NOME storico scontrini

cHistoryMask = This.PropGet(OVBCassa.ECR_Configuration, 'MaskStorico', '<AAAA>\<MM>\<GG>\<NUMSC>-<HHMMSS>.txt')

This.AddProperty('cHistoryMask', ADDBS(This.cStoryTO) + cHistoryMask )



** This.cNameLCD

cNameLCD = This.xTran4ScName(This.cNameMask, NULL) 

This.AddProperty('cNameLCD', cNameLCD)



cResultMask = This.PropGet(OVBCassa.ECR_Configuration, 'MaskAnswer', '')

This.AddProperty('cResultMask', ADDBS(This.cAnswerFolder) + cResultMask)



** THIS.PosTimeout		Tempo di attesa base

nPosTimeOut = This.PropGet(OVBCassa.ECR_Configuration, 'PosTimeOut', '5')

This.AddProperty('nPosTimeout', VAL(nPosTimeOut))



** THIS.PosRowtime		Tempo di attesa base

nPosRowtime = This.PropGet(OVBCassa.ECR_Configuration, 'PosRowtime', '1')

This.AddProperty('nPosRowtime', VAL(nPosRowtime))





** LCD: Pulizia display

cMess1 = PADL("", 20, " ")

cMess2 = PADL("", 20, " ")

&& Prevede un unica scritta da 40 caratteri (La cassa va a capo in automatico)

&& Il beep è previsto solo sulle FP90II e FP90III per cui non lo inserisco

&& Sarebbe displayText|<OPT>, ma per ora assumo che l'operatore sia 1 per default sul display

TEXT TO cSTRING TEXTMERGE PRETEXT 7

	printerCommand

	displayText|1|<<cMess1+cMess2>> 

ENDTEXT

This.AddProperty('cBlankString', CSTRING)



** LCD: Inizio scontrino/documento

cMess1 = "INIZIO"

cMess2 = "DOCUMENTO" && Era scontrino

&& Prevede un unica scritta da 40 caratteri

&& Il beep è previsto solo sulle FP90II e FP90III per cui non lo inserisco

TEXT TO CSTRING TEXTMERGE PRETEXT 7

	printerCommand

	displayText|1|<<PADC(cMess1, 20, ' ') + PADC(cMess2, 20, ' ')>>	

ENDTEXT

This.AddProperty('cStartString', CSTRING)



** RCF: SUBTOTALE

&& CSTRING = "SUBT" + _EOL_

TEXT TO CSTRING TEXTMERGE PRETEXT 7

	printRecSubtotal|<OPT>|1		

ENDTEXT

This.AddProperty('cSubt4ECR', CSTRING+_EOL_)



** LCD: SUBTOTALE

cMess1 = "SUBTOTALE pz<QTA>" 	&& 12+8 per qta

cMess2 = "EURO <IMPORTO>"		&& 5+15 per prezzo 

&& Prevede un unica scritta da 40 caratteri

&& Il beep è previsto solo sulle FP90II e FP90III per cui non lo inserisco

TEXT TO CSTRING TEXTMERGE PRETEXT 7

	printerCommand

	displayText|1|<<cMess1 + cMess2>>	

ENDTEXT

This.AddProperty('cSubt4LCD', CSTRING)



** ECR: Riferimento codice lotteria

TEXT TO CSTRING TEXTMERGE PRETEXT 7

	printRecLotteryId|<OPT>|<LOTTERYID>

ENDTEXT

This.AddProperty('cLottery4ECR', CSTRING+_EOL_)



** ECR: Sconto sul subtotale

&& CSTRING = "SCONTO VALORE=<IMPORTO>, SUBT" + _EOL_

TEXT TO CSTRING TEXTMERGE PRETEXT 7

	printRecSubtotalAdjustment|<OPT>|SCONTO|1|<IMPORTO>|1|1	

ENDTEXT

This.AddProperty('cSconto4ECR', CSTRING+_EOL_)



** ECR: Stringa per la stampa dello sconto di riga

&& CSTRING = "SCONTO VAL=<IMPORTO>, DES='<DESCRIZIONE>'"+ _EOL_

TEXT TO CSTRING TEXTMERGE PRETEXT 7

	printRecItemAdjustment|<OPT>|<DESCRIZIONE>|0|<IMPORTO>|<REP>|1	

ENDTEXT

This.AddProperty('cScontoRiga4ECR', CSTRING) && Non metto +_EOL_ perchè viene aggiunto eventualmente da iuistrtran4prn



*!*	0='CONTANTE'			;Lire in cassa

*!*	1='ASSEGNI'				;Assegni in cassa

*!*	2='CREDITI'				;Crediti/Carte di credito (?)

*!*	3='BUONI'				;Buoni in cassa



&& ECR: Pagamento in contanti

&& CSTRING = "CHIUS T=1, IMPORTO=<IMPORTO>" + _EOL_

TEXT TO CSTRING TEXTMERGE PRETEXT 7

	printRecTotal|<OPT>|CONTANTE|<IMPORTO>|0|0|1	

ENDTEXT

This.AddProperty('cCassa4ECR', CSTRING+_EOL_)



&& ECR: Credito

&& CSTRING = "CHIUS T=2, IMPORTO=<IMPORTO>" + _EOL_

TEXT TO CSTRING TEXTMERGE PRETEXT 7

	printRecTotal|<OPT>|CREDITO|<IMPORTO>|2|0|1	

ENDTEXT

This.AddProperty('cCrediti4ECR', CSTRING+_EOL_)



&& ECR: Credito

&& CSTRING = "CHIUS T=3, IMPORTO=<IMPORTO>" + _EOL_

TEXT TO CSTRING TEXTMERGE PRETEXT 7

	printRecTotal|<OPT>|ASSEGNI|<IMPORTO>|1|0|1	

ENDTEXT

This.AddProperty('cAssegni4ECR', CSTRING+_EOL_)



&& ECR: Ticket/Buoni

&& CSTRING = "CHIUS T=4, IMPORTO=<IMPORTO>" + _EOL_

&& 24.02.2020: Nel caso dei Ticket/Buoni il valore dopo il tipo di pagamento |3|

&& deve essere un valore 1..10(?) perchè si deve indicare il tipo di ticket

TEXT TO CSTRING TEXTMERGE PRETEXT 7

	printRecTotal|<OPT>|TICKET/BUONI|<IMPORTO>|3|1|1	

ENDTEXT

This.AddProperty('cBuoni4ECR', CSTRING+_EOL_)

This.AddProperty('cTicket4ECR', CSTRING+_EOL_)



&& ECR: Ticket/Buoni

&& CSTRING = "CHIUS T=5, IMPORTO=<IMPORTO>" + _EOL_

TEXT TO CSTRING TEXTMERGE PRETEXT 7

	printRecTotal|<OPT>|POS/CARTE DI CREDITO|<IMPORTO>|2|1|1	

ENDTEXT

This.AddProperty('cCarteDiCredito4ECR', CSTRING+_EOL_)

This.AddProperty('cPos4ECR', CSTRING+_EOL_)



&& ECR: Non riscosso servizi

TEXT TO CSTRING TEXTMERGE PRETEXT 7

	printRecTotal|<OPT>|NON CORRISPOSTO SERVIZI|<IMPORTO>|5|2|1	

ENDTEXT

This.AddProperty('cNonRiscossoServizi4ECR', CSTRING+_EOL_)



&& ECR: Non riscosso beni

TEXT TO CSTRING TEXTMERGE PRETEXT 7

	printRecTotal|<OPT>|NON CORRISPOSTO BENI|<IMPORTO>|5|1|1	

ENDTEXT

This.AddProperty('cNonRiscossoBeni4ECR', CSTRING+_EOL_)



&& ECR: Non riscosso SSN

TEXT TO CSTRING TEXTMERGE PRETEXT 7

	printRecTotal|<OPT>|NON CORRISPOSTO SSN|<IMPORTO>|5|5|1	

ENDTEXT

This.AddProperty('cNonRiscossoSSN4ECR', CSTRING+_EOL_)



&& ECR: Non riscosso fatture

TEXT TO CSTRING TEXTMERGE PRETEXT 7

	printRecTotal|<OPT>|NON CORRISPOSTO FATTURE|<IMPORTO>|5|3|1	

ENDTEXT

This.AddProperty('cNonRiscossoFatture4ECR', CSTRING+_EOL_)



&& ECR: Sconto a pagare

TEXT TO CSTRING TEXTMERGE PRETEXT 7

	printRecTotal|<OPT>|SCONTO A PAGARE|<IMPORTO>|6|0|1	

ENDTEXT

This.AddProperty('cScontoAPagare4ECR', CSTRING+_EOL_)



*********************************************************************

* ATTENZIONE !!!!! I SUBTENDER 125 e 126, vengono gestiti come 

* POS e TICKET la cassa deve essere correttamente impostata.

*********************************************************************

&& CSTRING = "INP NUM=<IMPORTO>, T=125" + _EOL_

&& This.AddProperty('cPos4ECR', CSTRING)



&& CSTRING = "INP NUM=<IMPORTO>, T=126" + _EOL_

&& This.AddProperty('cTicket4ECR', CSTRING)

*******************************************************



&& LCD: ANNULLAMENTO SCONTRINO

cMess1 = " DOCUMENTO "

cMess2 = " ANNULLATO "

&& Prevede un unica scritta da 40 caratteri

&& Il beep è previsto solo sulle FP90II e FP90III per cui non lo inserisco

TEXT TO CSTRING TEXTMERGE PRETEXT 7

	printerCommand

	displayText|1|<<PADC(cMess1, 20, '*') + PADC(cMess1, 20, '*')>>	

ENDTEXT

This.AddProperty('cAnnullaScontrino4LCD', CSTRING)



** LCD: RIGA DI VENDITA

cMess1 = "<DESCRIZIONE>"

cMess2 = "<UM><QTA> e <IMPORTO>"

&& Prevede un unica scritta da 40 caratteri

&& Il beep è previsto solo sulle FP90II e FP90III per cui non lo inserisco

TEXT TO CSTRING TEXTMERGE PRETEXT 7

	printerCommand

	displayText|1|<<cMess1 + cMess2>>	

ENDTEXT

This.AddProperty('cVend4LCD', CSTRING)



** ECR: RIGA DI VENDITA

&& CSTRING = "VEND REP=<REP>" + CSEP + "DES='<DESCRIZIONE>'" + CSEP + 'QTY=<QTA>' + CSEP + 'PRE=<PREZZO>' + _EOL_

TEXT TO CSTRING TEXTMERGE PRETEXT 7

	printRecItem|<OPT>|<DESCRIZIONE>|<QTA>|<PREZZO>|<REP>|1	

ENDTEXT

This.AddProperty('cVend4ECR', CSTRING) && Non metto +_EOL_ perchè viene aggiunto eventualmente da iuistrtran4prn



** LCD: RIGA DI RESO

cMess1 = "<DESCRIZIONE>"

cMess2 = "'<UM><QTA> e <IMPORTO>'"

&& Prevede un unica scritta da 40 caratteri

&& Il beep è previsto solo sulle FP90II e FP90III per cui non lo inserisco

TEXT TO CSTRING TEXTMERGE PRETEXT 7

	printerCommand

	displayText|1|<<cMess1 + cMess2>>	

ENDTEXT

This.AddProperty('cReso4LCD', CSTRING)



** ECR: RICHIESTA DI ANNULLO

TEXT TO CSTRING TEXTMERGE PRETEXT 7

	printRecMessage|<OPT>|4|1|1|VOID <NUMCH> <NUMSC> <DATASC> <MATRICOLA>

ENDTEXT

This.AddProperty('cAnnulloReq4ECR', CSTRING)



** ECR: RICHIESTA DI RESO

TEXT TO CSTRING TEXTMERGE PRETEXT 7

	printRecMessage|<OPT>|4|1|1|REFUND <NUMCH> <NUMSC> <DATASC> <MATRICOLA>

ENDTEXT

This.AddProperty('cResoReq4ECR', CSTRING)



** ECR: RIGA DI RESO (DETTAGLIO)

** Il comando della riga di reso è lo stesso della vendita, 

** non appena attivata la richiesta (cResoReq4ECR).

** Questo perchè gli importi vanno indicati in positivo,

** in caso contrario dopo la prima riga la cassa si blocca

** PS Controllare il comando printRecVoid

TEXT TO CSTRING TEXTMERGE PRETEXT 7

	printRecItem|<OPT>|<DESCRIZIONE>|<QTA>|<PREZZO>|<REP>|1		

ENDTEXT

This.AddProperty('cReso4ECR', CSTRING)



** Il campo separatore può servire ad altri metodi, per cui lo imposto come property.

This.AddProperty('CSEP', CSEP)



return	DODEFAULT(oVBCassa, oOperatore)

ENDPROC

PROCEDURE iuiformatval

Lparameters nValue



&& return chrtran(alltrim(str(nValue, 10, 2)), ',', '.')

return chrtran(alltrim(str(nValue, 10, 2)), '.', ',') && Separatore decimale ','

ENDPROC

PROCEDURE iuidisplaymsg

Lparameters cMsg



DODEFAULT(cmsg)

ENDPROC

PROCEDURE iuisendcmd

Lparameters cString2send



STRTOFILE(cString2Send, This.cNameLCD)



ENDPROC

PROCEDURE iuiscqueryemit

Lparameters oVbCausale, oVBSconT, oColVBSconR, oColVBSconP



LOCAL lEmit



lEmit = .T.



IF lEmit AND VARTYPE(oVBCausale) = 'O'

	** EFFETTUO IL CONTROLLO SULLA CAUSALE

	lEmit = !oVBCausale.NonInviaScontrino

* ff *		DO case

* ff *			CASE INLIST(oVBCausale.In, 'VE ', 'VEN')

* ff *				lContinue = .T.

* ff *			OTHERWISE

* ff *				lContinue = .F.

* ff *		ENDCASE

ENDIF



IF lEmit AND VARTYPE(oVBSconT) = 'O'

	** EFFETTUO IL CONTROLLO SULLA TESTA DEL DOCUMENTO

ENDIF



IF lEmit AND VARTYPE(oColVBSconR) = 'O'

	** EFFETTUO IL CONTROLLO SULLE RIGHE DEL DOCUMENTO

ENDIF



IF lEmit AND VARTYPE(oColVBSconP) = 'O'

	** EFFETTUO IL CONTROLLO SUI PAGAMENTI.

ENDIF



RETURN lEmit 



ENDPROC


*======================================================================

