FUNCTION xGetIdTesta_R
PARAMETERS myID_Riga
LOCAL sqlStmt
LOCAL myID_Testa

	myID_Testa = 0
	IF !EMPTY(myID_Riga) THEN 
		TEXT TO sqlStmt TEXTMERGE
			SELECT Id_DoTes FROM DoRig WHERE Id_DoRig = <<Format4Spt(myID_Riga)>>
		ENDTEXT
		oInfo = xSQLExec2Obj(sqlStmt)
		IF VARTYPE(oInfo) = 'O' THEN 
		   myID_Testa = oInfo.Id_DoTes 
		ENDIF
	ENDIF
	
	RETURN myID_Testa
	
ENDFUNC
