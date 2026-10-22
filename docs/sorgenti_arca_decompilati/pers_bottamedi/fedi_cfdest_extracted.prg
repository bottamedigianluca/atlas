*** Extracted Visual FoxPro Source Code from fedi_cfdest.vcx ***

*** CLASS / OBJECT: fedi (BaseClass: form, Parent: ) ***
*** PROPERTIES ***
DoCreate = .T.
Name = "fedi"
statusbar.Top = 462
statusbar.Left = 0
statusbar.Height = 20
statusbar.Width = 583
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
PF.pgGenerale.txtCd_CF.Label.Name = "Label"
PF.pgGenerale.txtCd_CF.field.Name = "field"
PF.pgGenerale.txtCd_CF.DISPLAY.Name = "DISPLAY"
PF.pgGenerale.txtCd_CF.Name = "txtCd_CF"
PF.pgGenerale.txtCd_CFDest.Label.Name = "Label"
PF.pgGenerale.txtCd_CFDest.field.Name = "field"
PF.pgGenerale.txtCd_CFDest.Name = "txtCd_CFDest"
PF.pgGenerale.txtDescrizione.Label.Name = "Label"
PF.pgGenerale.txtDescrizione.field.Name = "field"
PF.pgGenerale.txtDescrizione.Name = "txtDescrizione"
PF.pgGenerale.txtIndirizzo.Label.Name = "Label"
PF.pgGenerale.txtIndirizzo.field.Name = "field"
PF.pgGenerale.txtIndirizzo.Name = "txtIndirizzo"
PF.pgGenerale.txtCap.Label.Name = "Label"
PF.pgGenerale.txtCap.field.Name = "field"
PF.pgGenerale.txtCap.Name = "txtCap"
PF.pgGenerale.txtLocalita.Label.Name = "Label"
PF.pgGenerale.txtLocalita.field.Name = "field"
PF.pgGenerale.txtLocalita.Name = "txtLocalita"
PF.pgGenerale.txtCd_Agente.Label.Name = "Label"
PF.pgGenerale.txtCd_Agente.field.Name = "field"
PF.pgGenerale.txtCd_Agente.DISPLAY.Name = "DISPLAY"
PF.pgGenerale.txtCd_Agente.Name = "txtCd_Agente"
PF.pgGenerale.txtCd_CFZona.Label.Name = "Label"
PF.pgGenerale.txtCd_CFZona.field.Name = "field"
PF.pgGenerale.txtCd_CFZona.DISPLAY.Name = "DISPLAY"
PF.pgGenerale.txtCd_CFZona.Name = "txtCd_CFZona"
PF.pgGenerale.txtEmail.Label.Name = "Label"
PF.pgGenerale.txtEmail.field.Name = "field"
PF.pgGenerale.txtEmail.Stdbtn1.Name = "Stdbtn1"
PF.pgGenerale.txtEmail.Stdbtn2.Name = "Stdbtn2"
PF.pgGenerale.txtEmail.Name = "txtEmail"
PF.pgGenerale.txtCd_DOVettore.Label.Name = "Label"
PF.pgGenerale.txtCd_DOVettore.field.Name = "field"
PF.pgGenerale.txtCd_DOVettore.DISPLAY.Name = "DISPLAY"
PF.pgGenerale.txtCd_DOVettore.Name = "txtCd_DOVettore"
PF.pgGenerale.txtTelefono.Label.Name = "Label"
PF.pgGenerale.txtTelefono.field.Name = "field"
PF.pgGenerale.txtTelefono.Name = "txtTelefono"
PF.pgGenerale.txtFax.Label.Name = "Label"
PF.pgGenerale.txtFax.field.Name = "field"
PF.pgGenerale.txtFax.Name = "txtFax"
PF.pgGenerale.txtPersonaRiferimento.Label.Name = "Label"
PF.pgGenerale.txtPersonaRiferimento.field.Name = "field"
PF.pgGenerale.txtPersonaRiferimento.Name = "txtPersonaRiferimento"
PF.pgGenerale.txtCd_NazioneProvincia.Label.Name = "Label"
PF.pgGenerale.txtCd_NazioneProvincia.Display1.Name = "Display1"
PF.pgGenerale.txtCd_NazioneProvincia.Display2.Name = "Display2"
PF.pgGenerale.txtCd_NazioneProvincia.Field1.Name = "Field1"
PF.pgGenerale.txtCd_NazioneProvincia.Field2.Name = "Field2"
PF.pgGenerale.txtCd_NazioneProvincia.Label2.Name = "Label2"
PF.pgGenerale.txtCd_NazioneProvincia.Name = "txtCd_NazioneProvincia"
PF.pgGenerale.TxtCd_CACda.Label.Name = "Label"
PF.pgGenerale.TxtCd_CACda.field.Name = "field"
PF.pgGenerale.TxtCd_CACda.DISPLAY.Name = "DISPLAY"
PF.pgGenerale.TxtCd_CACda.Name = "TxtCd_CACda"
PF.pgGenerale.txtCd_Aliquota.Label.Name = "Label"
PF.pgGenerale.txtCd_Aliquota.field.Name = "field"
PF.pgGenerale.txtCd_Aliquota.DISPLAY.Name = "DISPLAY"
PF.pgGenerale.txtCd_Aliquota.Name = "txtCd_Aliquota"
PF.pgGenerale.txtCodiceIPA.Label.Name = "Label"
PF.pgGenerale.txtCodiceIPA.field.Name = "field"
PF.pgGenerale.txtCodiceIPA.btnSearch.Name = "btnSearch"
PF.pgGenerale.txtCodiceIPA.Name = "txtCodiceIPA"
PF.pgGenerale.Title_label1.Name = "Title_label1"
PF.pgGenerale.Title_label3.Name = "Title_label3"
PF.pgGenerale.Title_label2.Name = "Title_label2"
PF.pgGenerale.chkDefaultDestinazione.Alignment = 0
PF.pgGenerale.chkDefaultDestinazione.Name = "chkDefaultDestinazione"
PF.pgGenerale.Title_label4.Name = "Title_label4"
PF.pgGenerale.btnMaps.Name = "btnMaps"
PF.pgGenerale.txtNote.Label.Name = "Label"
PF.pgGenerale.txtNote.field.Name = "field"
PF.pgGenerale.txtNote.Name = "txtNote"
PF.pgGenerale.PageOrder = 2
PF.pgGenerale.Name = "pgGenerale"
PF.Name = "PF"

*** METHODS ***
PROCEDURE PF.Init
LOCAL oPage
oPage  = This.NewPage('xExport', 'Export')
MNewObject1(oPage, 'cnt', 'xExport', Thisform.ClassLibrary, '', oPage)
RETURN DODEFAULT()

ENDPROC

*======================================================================

