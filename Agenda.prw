#include 'protheus.ch'

// Macro para calcular o tamanho (WIDTH) cada GET da tela
// baseado no tamanho do campo caractere de entrada
#define CALCSIZEGET( X )  (( X * 4 ) + 4)

/* =============================================================================

Funcao 	U_AGENDA()
Autor	Julio Wittwer
Data 	30/09/2018

Fun��o principal da Agenda, CRUD b�sico montada em cima de uma DIALOG
Deve ser chamada diretamente pelo SmartClient, n�o depende do Framework do ERP
Criada utilizando apenas as fun��es b�sicas da linguagem AdvPL

Release 1.1 em 05/10/2018

Corre��o - Ap�s cancelar uma altera��o, atualiza os campos da tela 
           com o conte�do original do registro
           
Melhoria - Cria Novo ID apenas na hora de gravar

Melhoria - Inserir valida��o no campo UF, para permitir ou um valor em branco, ou 
           um valor v�lido
                  
Melhoria - Inserir campos FONE1, FONE2, e EMAIL


Melhoria - Implementar busca indexada por ID e NOME

============================================================================= */

User Function Agenda()
Local oFont
Local oDlg
Local cTitle := "CRUD - Agenda"

// Define Formato de data DD/MM/AAAA
SET DATE BRITISH
SET CENTURY ON

// Usa uma fonte Fixed Size
oFont := TFont():New('Courier new',,-14,.T.)

// Cria a janela principal da Agenda como uma DIALOG
DEFINE DIALOG oDlg TITLE (cTitle) ;
	FROM 0,0 TO 420,830 ;
	FONT oFont ;
	COLOR CLR_BLACK, CLR_LIGHTGRAY PIXEL

// Ativa a janela principal
// O contexto da Agenda e os componentes s�o colocados na tela
// pela fun��o DoInit()

ACTIVATE DIALOG oDlg CENTER ;
	ON INIT MsgRun("Aguarde...","Iniciando AGENDA", {|| DoInit(oDlg) }) ;
	VALID CanQuit()

// Fecha contexto da Agenda
CloseAgenda()

return

/* ------------------------------------------
Inicializa��o da Aplica��o
Cria pain[eis e um menu de op��es com bot�es
------------------------------------------ */

STATIC Function doInit(oDlg)
Local oPanelMenu, oPanelCrud, oPanelNav
Local oBtn1,oBtn2,oBtn3,oBtn4,oBtn5,oBtn6
Local oSay1,oSay2,oSay3,oSay4,oSay5,oSay6,oSay7,oSay8,oSay9,oSayA,oSayB
Local oGet1,oGet2,oGet3,oGet4,oGet5,oGet6,oGet7,oGet8,oGet9,oGetA,oGetB
Local oBtnFirst, oBtnPrev, oBtnNext, oBtnLast, oBtnPesq, oBtnOrd
Local oSayOrd
Local aGets := {}
Local aBtns := {}
Local nMode := 0

Local cID      := Space(6)
Local cNome    := Space(50)
Local cEnder   := Space(50)
Local cCompl   := Space(20)
Local cBairro  := Space(30)
Local cCidade  := Space(40)
Local cUF      := Space(2)
Local cCEP     := Space(8)
Local cFone1   := Space(20)
Local cFone2   := Space(20)
Local cEmail   := Space(40)

CursorArrow() ; CursorWait()

// Abre contexto de dados da agenda
If !OpenAgenda()
	oDlg:End()
	Return .F.
Endif

@ 0,0 MSPANEL oPanelMenu OF oDlg SIZE 70,600 COLOR CLR_WHITE,CLR_GRAY
oPanelMenu:ALIGN := CONTROL_ALIGN_LEFT

@ 0,0 MSPANEL oPanelNav OF oDlg SIZE 70,600 COLOR CLR_WHITE,CLR_GRAY
oPanelNav:ALIGN := CONTROL_ALIGN_RIGHT

@ 0,0 MSPANEL oPanelCenter OF oDlg SIZE 700,600 COLOR CLR_WHITE,CLR_LIGHTGRAY
oPanelCenter:ALIGN := CONTROL_ALIGN_ALLCLIENT

@ 0,0 MSPANEL oPanelOrd OF oPanelCenter SIZE 100,20 COLOR CLR_WHITE,CLR_BLUE
oPanelOrd:ALIGN := CONTROL_ALIGN_TOP

@ 0,0 MSPANEL oPanelCrud OF oPanelCenter SIZE 700,600 COLOR CLR_WHITE,CLR_LIGHTGRAY
oPanelCrud:ALIGN := CONTROL_ALIGN_ALLCLIENT
                
// Mostra Ordena��o atual do arquivo de agenda 

@   5,5 SAY oSayOrd PROMPT " " SIZE 100,12 COLOR CLR_WHITE,CLR_BLUE OF oPanelOrd PIXEL
oSayOrd:SetText("Ordem .... "+ AGENDA->(IndexKey()))

// Cria os bot�es no Painel Lateral ( Menu )

@ 05,05  BUTTON oBtn1 PROMPT "Incluir" SIZE 60,15 ;
	ACTION ManAgenda(oDlg,aBtns,aGets,1,@nMode,oSayOrd) OF oPanelMenu PIXEL
aadd(aBtns,oBtn1) // Botcao de Inclusao

@ 20,05  BUTTON oBtn2 PROMPT "Alterar" SIZE 60,15 ;
	ACTION ManAgenda(oDlg,aBtns,aGets,2,@nMode,oSayOrd) OF oPanelMenu PIXEL
aadd(aBtns,oBtn2) // Botao de altera��o

@ 35,05  BUTTON oBtn3 PROMPT "Excluir" SIZE 60,15 ;
	ACTION ManAgenda(oDlg,aBtns,aGets,3,@nMode,oSayOrd) OF oPanelMenu PIXEL
aadd(aBtns,oBtn3) // Bot�o de exclus�o

@ 50,05  BUTTON oBtn4 PROMPT "Consultar" SIZE 60,15 ;
	ACTION ManAgenda(oDlg,aBtns,aGets,4,@nMode,oSayOrd) OF oPanelMenu PIXEL
aadd(aBtns,oBtn4) // Bot�o de Consulta - Navega��o

@ 65,05  BUTTON oBtn5 PROMPT "Sair" SIZE 60,15 ;
	ACTION oDlg:End() OF oPanelMenu PIXEL

// -----------------------------------------------------------------------------
// Desenha os componentes a partir do Painel de Manuten��o
// Say sempre 3 linhas abaixo do GET
// -----------------------------------------------------------------------------

@   5+3,05 SAY oSay1 PROMPT "ID"          RIGHT SIZE 50,12 OF oPanelCrud PIXEL
@  20+3,05 SAY oSay2 PROMPT "Nome"        RIGHT SIZE 50,12 OF oPanelCrud PIXEL
@  35+3,05 SAY oSay3 PROMPT "Endere�o"    RIGHT SIZE 50,12 OF oPanelCrud PIXEL
@  50+3,05 SAY oSay4 PROMPT "Complemento" RIGHT SIZE 50,12 OF oPanelCrud PIXEL
@  65+3,05 SAY oSay5 PROMPT "Bairo"       RIGHT SIZE 50,12 OF oPanelCrud PIXEL
@  80+3,05 SAY oSay6 PROMPT "Cidade"      RIGHT SIZE 50,12 OF oPanelCrud PIXEL
@  95+3,05 SAY oSay7 PROMPT "UF"          RIGHT SIZE 50,12 OF oPanelCrud PIXEL
@ 110+3,05 SAY oSay8 PROMPT "CEP"         RIGHT SIZE 50,12 OF oPanelCrud PIXEL

// Novos campos inseridos em 07/10
@ 125+3,05 SAY oSay9 PROMPT "Fone 1"      RIGHT SIZE 50,12 OF oPanelCrud PIXEL
@ 140+3,05 SAY oSayA PROMPT "Fone 2"      RIGHT SIZE 50,12 OF oPanelCrud PIXEL
@ 155+3,05 SAY oSayB PROMPT "e-Mail"      RIGHT SIZE 50,12 OF oPanelCrud PIXEL

@   5,60 GET oGet1 VAR cID          PICTURE "@!"   SIZE CALCSIZEGET(6) ,12 OF oPanelCrud PIXEL
@  20,60 GET oGet2 VAR cNome        PICTURE "@!"   SIZE CALCSIZEGET(50),12 OF oPanelCrud PIXEL
@  35,60 GET oGet3 VAR cEnder       PICTURE "@!"   SIZE CALCSIZEGET(50),12 OF oPanelCrud PIXEL
@  50,60 GET oGet4 VAR cCompl       PICTURE "@!"   SIZE CALCSIZEGET(20),12 OF oPanelCrud PIXEL
@  65,60 GET oGet5 VAR cBairro      PICTURE "@!"   SIZE CALCSIZEGET(30),12 OF oPanelCrud PIXEL
@  80,60 GET oGet6 VAR cCidade      PICTURE "@!"   SIZE CALCSIZEGET(40),12 OF oPanelCrud PIXEL
@  95,60 GET oGet7 VAR cUF          PICTURE "!!"   SIZE CALCSIZEGET(2) ,12 VALID VldUf(cUF) OF oPanelCrud PIXEL
@ 110,60 GET oGet8 VAR cCEP         PICTURE "@R 99999-999" SIZE CALCSIZEGET(9),12 OF oPanelCrud PIXEL

// Novos campos inseridos em 07/10
@ 125,60 GET oGet9 VAR cFone1       PICTURE "@!" SIZE CALCSIZEGET(20),12 OF oPanelCrud PIXEL
@ 140,60 GET oGetA VAR cFone2       PICTURE "@!" SIZE CALCSIZEGET(20),12 OF oPanelCrud PIXEL
@ 155,60 GET oGetB VAR cEMAIL       PICTURE "@!" SIZE CALCSIZEGET(40),12 OF oPanelCrud PIXEL

// Acrescenta no array de GETS o nome do campo
// o objeto TGET correspondente
// e o valor inicial ( em branco ) do campo

aadd( aGets , {"ID"     , oGet1 , space(6)  } )
aadd( aGets , {"NOME"   , oGet2 , space(50) } )
aadd( aGets , {"ENDER"  , oGet3 , space(50) } )
aadd( aGets , {"COMPL"  , oGet4 , space(20) } )
aadd( aGets , {"BAIRR"  , oGet5 , space(30) } )
aadd( aGets , {"CIDADE" , oGet6 , space(40) } )
aadd( aGets , {"UF"     , oGet7 , space(2)  } )
aadd( aGets , {"CEP"    , oGet8 , space(8)  } )

// Novos campos inseridos em 07/10
aadd( aGets , {"FONE1"  , oGet9 , space(20)  } )
aadd( aGets , {"FONE2"  , oGetA , space(20)  } )
aadd( aGets , {"EMAIL"  , oGetB , space(40)  } )

// Cria os Bot�es de A��o sobre os dados
@ 175,60  BUTTON oBtnConf PROMPT "Confirmar" SIZE 60,15 ;
	ACTION ManAgenda(oDlg,aBtns,aGets,5,@nMode)  OF oPanelCrud PIXEL

aadd(aBtns,oBtnConf) // [5] Bot�o de Confirma��o

@ 175,125  BUTTON oBtnCanc PROMPT "Voltar" SIZE 60,15 ;
	ACTION ManAgenda(oDlg,aBtns,aGets,6,@nMode)  OF oPanelCrud PIXEL

aadd(aBtns,oBtnCanc) // [6] Bot�o de Cancelamento

// Cria os Bot�es de Navega��o Livre
@ 05,05  BUTTON oBtnFirst PROMPT "Primeiro" SIZE 60,15 ;
	ACTION ManAgenda(oDlg,aBtns,aGets,7,@nMode)  OF oPanelNav PIXEL
aadd(aBtns,oBtnFirst) // [7] Primeiro

@ 020,05  BUTTON oBtnPrev PROMPT "Anterior" SIZE 60,15 ;
	ACTION ManAgenda(oDlg,aBtns,aGets,8,@nMode)  OF oPanelNav PIXEL
aadd(aBtns,oBtnPrev) // [8] Anterior

@ 35,05  BUTTON oBtnNext PROMPT "Pr�ximo" SIZE 60,15 ;
	ACTION ManAgenda(oDlg,aBtns,aGets,9,@nMode)  OF oPanelNav PIXEL
aadd(aBtns,oBtnNext) // [9] Proximo

@ 50,05  BUTTON oBtnLast PROMPT "�ltimo" SIZE 60,15 ;
	ACTION ManAgenda(oDlg,aBtns,aGets,10,@nMode)  OF oPanelNav PIXEL
aadd(aBtns,oBtnLast) // [10] �ltimo

@ 65,05  BUTTON oBtnPesq PROMPT "Pesquisa" SIZE 60,15 ;
	ACTION ManAgenda(oDlg,aBtns,aGets,11,@nMode,oSayOrd)  OF oPanelNav PIXEL
aadd(aBtns,oBtnPesq) // [11] Pesquisa

@ 80,05  BUTTON oBtnOrd PROMPT "Ordem" SIZE 60,15 ;
	ACTION ManAgenda(oDlg,aBtns,aGets,12,@nMode,oSayOrd)  OF oPanelNav PIXEL
aadd(aBtns,oBtnOrd) // [12] Ordem

// Seta a interface para o estado inicial
// Habilita apenas inser��o e consulta 
nMode := 0
AdjustMode(oDlg,aBtns,aGets,nMode)

Return .T.

/* ------------------------------------------
Valida��o da Main Window - Quer realmente sair ?
------------------------------------------ */

STATIC Function CanQuit()
Return MsgYesNo("Deseja fechar a Agenda ?")


// --------------------------------------------------------------
// Abertura do contexto de DADOS da Agenda
// Cria uma tabela chamda "AGENDA" no Banco de dados atual
// configurado no Environment em uso pelo DBAccess
// Cria a tabela caso nao exista, cria os �ndices caso nao existam
// Abre e mant�m a tabela aberta em modo compartilhado
// --------------------------------------------------------------

STATIC Function OpenAgenda()
Local nH
Local cFile := "AGENDA"
Local aStru := {}
Local aDbStru := {}
Local nRet

// Conecta com o DBAccess configurado no ambiente
nH := TCLink()

If nH < 0
	MsgStop("DBAccess - Erro de conexao "+cValToChar(nH))
	QUIT
Endif

// Coloca um MUTEX na opera��o de criar/abrir o arquivo de Agenda
// Assim apenas um processo por vez realiza a manuten��o nas
// estruturas ou indices, caso necessario 

While !GlbNmLock("AGENDA_DB")
	If !MsgYesNo("Existe outro processo abrindo a Agenda. Deseja tentar novamente ?")
		MSgStop("Abertura da Agenda em uso -- tente novamente mais tarde.")
		QUIT
	Endif
Enddo

// Cria o array com os campos do arquivo 
	
aadd(aStru,{"ID"    ,"C",06,0})
aadd(aStru,{"NOME"  ,"C",50,0})
aadd(aStru,{"ENDER" ,"C",50,0})
aadd(aStru,{"COMPL" ,"C",20,0})
aadd(aStru,{"BAIRR" ,"C",30,0})
aadd(aStru,{"CIDADE","C",40,0})
aadd(aStru,{"UF"    ,"C",02,0})
aadd(aStru,{"CEP"   ,"C",08,0})

// Novos campos inseridos em 07/10
aadd(aStru,{"FONE1" ,"C",20,0})
aadd(aStru,{"FONE2" ,"C",20,0})
aadd(aStru,{"EMAIL" ,"C",40,0})

If !TCCanOpen(cFile)
	
	// Se o arquivo nao existe no banco, cria
	DBCreate(cFile,aStru,"TOPCONN")
	
Else

	// O Arquivo j� existe, vamos comparar as estruturas
	USE (cFile) ALIAS (cFile) SHARED NEW VIA "TOPCONN"
	IF NetErr()
		MsgSTop("Falha ao abrir a Agenda em modo compartilhado. Tente novamente mais tarde.")
		QUIT
	Endif
	aDbStru := DBStruct()
	USE
	
	If len(aDbStru) <> len(aStru)
		// O tamanho est� diferente ? 
		// Vamos alterar a estrutura da tabela
		// informamos a estrutura atual, e a estrutura esperada
		If !TCAlter(cFile,aDbStru,aStru)
			MsgSTop(tcsqlerror(),"Falha ao alterar a estrutura da AGENDA")
			QUIT
		Endif
		MsgInfo("Estrutura do arquivo AGENDA atualizada.")
	Endif
	
Endif

If !TCCanOpen(cFile,cFile+'_UNQ')
	// Se o Indice �nico da tabela nao existe, cria 
	USE (cFile) ALIAS (cFile) EXCLUSIVE NEW VIA "TOPCONN"
	IF NetErr()
		MsgSTop("Falha ao abrir a Agenda em modo EXCLUSIVO. Tente novamente mais tarde.")
		QUIT
	Endif
	nRet := TCUnique(cFile,"ID")
	If nRet < 0 
		MsgSTop(tcsqlerror(),"Falha ao criar �ndice �nico")
		QUIT
	Endif
	USE
EndIf

If !TCCanOpen(cFile,cFile+'1')
	// Se o Indice por ID nao existe, cria
	USE (cFile) ALIAS (cFile) EXCLUSIVE NEW VIA "TOPCONN"
	IF NetErr()
		MsgSTop("Falha ao abrir a Agenda em modo EXCLUSIVO. Tente novamente mais tarde.")
		QUIT
	Endif
	INDEX ON ID TO (cFile+'1')
	USE
EndIf

If !TCCanOpen(cFile,cFile+'2')
	// Se o indice por nome nao existe, cria
	USE (cFile) ALIAS (cFile) EXCLUSIVE NEW VIA "TOPCONN"
	IF NetErr()
		MsgSTop("Falha ao abrir a Agenda em modo EXCLUSIVO. Tente novamente mais tarde.")
		QUIT
	Endif
	INDEX ON NOME TO (cFile+'2')
	USE
EndIf

// Abra o arquivo de agenda em modo compartilhado
USE (cFile) ALIAS AGENDA SHARED NEW VIA "TOPCONN"

If NetErr()
	MsgSTop("Falha ao abrir a Agenda em modo compartilhado. Tente novamente mais tarde.")
	QUIT
Endif

// Liga o filtro para ignorar registros deletados 
SET DELETED ON 

// Abre os indices, seleciona ordem por ID
// E Posiciona no primeiro registro 
DbSetIndex(cFile+'1')
DbSetIndex(cFile+'2')
DbSetOrder(1)
DbGoTop()

// Solta o MUTEX 
GlbNmUnlock("AGENDA_DB")

Return .T.

// ----------------------------------------------------------------------
// Funcao de encerramento do contexto de dados da Agenda
// Fecha todos os alias abertos, encerra a conex�o com o DBAccess

STATIC Function CloseAgenda()

DBCloseAll()   // Fecha todas as tabelas
Tcunlink()     // Desconecta do DBAccess

Return

// Limpa o conteudo dos GETS,
// e permite habilitar ou desabilitar a edi��o
STATIC Function ClearGets(aGets,lEnable)
Local nI , nT := len(aGets)
For nI := 1 to nT
	
	// Utiliza o codeblock de Set/Get do Objeto TGET para atribuir
	// os valores iniciais para cada get ( todos em branco )
	EVAL( aGets[nI][2]:bSetGet , aGets[nI][3] )
	
	// Aproveita e habilita ou desabilita a edi��o
	// de acordo com o parametro recebido
	If lEnable
		aGets[nI][2]:Enable()
	Else
		aGets[nI][2]:Disable()
	Endif
	
Next
Return


// Nao mexe no conteudo dos GETS,
// Permite apenas habilitar ou desabilitar a edi��o
STATIC Function EnableGets(aGets,lEnable)
Local nI , nT := len(aGets)
For nI := 1 to nT
	If lEnable
		aGets[nI][2]:Enable()
	Else
		aGets[nI][2]:Disable()
	Endif
Next
Return


/* ------------------------------------------
Manuten��o da Agenda
Centraliza todas as opera��es
Monta o formul�rio baseado na a��o escolhida
Cria uma janela de di�logo para fazer as opera��es 
A fun��o atual faz toda a manuten��o e navega��o da Agenda
------------------------------------------ */

STATIC Function ManAgenda(oDlg,aBtns,aGets,nAction,nMode,oSayOrd)
Local nI , nT
Local cNewId
Local lVolta

If nAction == 1
	
	// Inicio da Inclusao -- Novo contato 
	
	// Limpa todos os valores de tela,
	// habilitando os campos para edi��o
	ClearGets(aGets , .T. )

	// Release 1.1
	// Nao abre o campo ID para edi��o 
	// E nao gera o numero agora, somente na hora de gravar
	aGets[1][2]:Disable()
	
	// Joga o foco para o nome
	aGets[2][2]:SetFocus()
	
	// Seta que o modo atual � Inclusao
	nMode := 1
	AdjustMode(oDlg,aBtns,aGets,nMode)
	
ElseIf nAction == 2
	
	// Altera��o
	
	// Se a altera��o est� habilitada, eu estou posicionado
	// em um registro para alterar . Apenas habilita os GETS, sem mexer no conteuido 
	EnableGets(aGets,.T.)
	
	// Nao permite alterar o ID
	aGets[1][2]:Disable()
	
	// Joga o foco para o nome
	aGets[2][2]:SetFocus()
	
	// Seta que o modo atual � Altera��o
	nMode := 2
	AdjustMode(oDlg,aBtns,aGets,nMode)
	
ElseIf nAction == 3
	
	// Exclusao
	// Se a exclus�o est� habilitada, eu estou posicionado em um registro
	
	// Seta que o modo atual � Exclus�o
	nMode := 3
	AdjustMode(oDlg,aBtns,aGets,nMode)
	
ElseIf nAction == 4
	
	// Entrou no modo de Consulta / Navega��o
	
	DBSelectArea("AGENDA")
	
	// Primeiro verifica se tem alguma coisa para ser mostrada
	If BOF() .and. EOF()
		MsgStop("N�o h� registros na Agenda.","Consultar")
		Return .F.
	Endif
	
	// Consulta em ordem alfab�tica, inicia no primeiro registro
	DbsetOrder(2)
	DBGotop()
	
	// Atualiza texto com a ordem 
	oSayOrd:SetText("Ordem .... "+ AGENDA->(IndexKey()))
	
	// Coloca os dados do registro na tela
	ReadRecord(aGets)
	
	// Seta que o modo atual � Consulta
	nMode := 4
	AdjustMode(oDlg,aBtns,aGets,nMode)
	
ElseIf nAction == 5  // Confirma
	
	IF nMode == 1
		
		// Confirmando uma inclusao

		// Release 1.1
		// Usa uma funcao para criar um novo ID para a Agenda
		cNewID := GetNewID()

		// Release 1.2
		// Se o ID est� vazio, nao foi possivel obter o Semaforo
		// para a gera��o do ID -- Muitas opera��es de inser��o concorentes
				
		While empty(cNewID)

			If MsgInfo("Falha ao obter um novo ID para inclus�o. Deseja tentar novamente ?")
				cNewID := GetNewID()
				LOOP
			Endif   
			
			MsgStop("N�o � poss�vel incluir na agenda neste momento. Tente novamente mais tarde.")
			Return
			
		Enddo

		// Coloca o valor no GET 
		EVAL( aGets[1][2]:bSetGet , cNewId )
		
		DBSelectArea("AGENDA")

		// Inicia uma inser��o
		DBAppend()   
		
		// Coloca o valor dos GETs nos respectivos campos do Alias
		PutRecord(aGets)
		
		// Solta o lock pego automaticamente na inclusao
		// fazendo o flush do registro
		DBRUnlock()

		// Volta para a ordem alfab�tica 		
		dbsetorder(2)

		// Atualiza texto com a ordem 
		oSayOrd:SetText("Ordem .... "+ AGENDA->(IndexKey()))
		
		// Volta ao modo inicial
		nMode := 0
		AdjustMode(oDlg,aBtns,aGets,nMode)
		
	ElseIF nMode == 2
		
		// Confirmando uma altera��o
		
		DBSelectArea("AGENDA")
		
		If DbrLock(recno())
			
			// Caso tenhha obtido o LOCK para altera��o do registro
			// Coloca o valor dos GETs nos respectivos campos do Alias
			PutRecord(aGets)
			
			// Solta o lock obtido para altera��o
			DBRUnlock()
			
			// Retorna ao modo de consulta
			nMode := 4
			AdjustMode(oDlg,aBtns,aGets,nMode)
			
		Else
			
			// Nao conseguiu bloqueio do registro
			// Mostra a mensagem e permanece no modo de altera��o
			MsgStop("Registro n�o pode ser alterado, est� sendo usado por outro usu�rio")
			
		Endif
		
	ElseIF nMode == 3
		
		// Confirmando uma exclus�o
		
		If DbrLock(recno())
			
			// Apaga o registro ( marca para dele��o )
			DBDelete()
			
			// E tenta posicionar no registro anterior
			DbSkip(-1)
			
			If BOF()
			    // Se j� estava no primeiro registro, 
			    // volta para o topo do arquivo 
				DbGoTOP()			
			Endif

			If BOF() .and. EOF()
				                              
				// Se nao tem mais registros visiveis, volta ao estado inicial
				MsgStop("N�o h� mais registros para visualiza��o")
				
				// Volta ao modo inicial
				nMode := 0
				AdjustMode(oDlg,aBtns,aGets,nMode)
				
			Else
			
				// Coloca os dados do registro atual na tela
				ReadRecord(aGets)

				// Retorna ao modo de consulta
				nMode := 4
				AdjustMode(oDlg,aBtns,aGets,nMode)
				
			Endif
			
			
		Else
			
			// Nao conseguiu bloqueio do registro
			// Mostra a mensagem e volta para o modo de consulta
			MsgStop("Registro n�o pode ser apagado, est� sendo usado por outro usu�rio")
	
			nMode := 4
			AdjustMode(oDlg,aBtns,aGets,nMode)
			
		Endif
		
		
	Else
		
		// Confirma��o somente � habilitada para inclus�o, altera��o e exclus�o
		UserException("Unexpected Mode "+cValToChaR(nMode))
		
	Endif
	
	// Atualiza os componentes da tela
	oDlg:Refresh()
	
ElseIf nAction == 6  // Voltar / Abandonar opera��o atual
	
	lVolta := .T.
	
	IF nMode == 1
		// Pergunta se deseja cancelar a inclus�o
		// Avisa que qualquer dado digitado ser� perdido
		lVolta := MsgYesNo("Deseja cancelar a inclus�o ? Os dados digitados ser�o perdidos.")
	ElseIF nMode == 2
		// Pergunta se deseja cancelar a altera��o
		// Avisa que qualquer dado digitado ser� perdido
		lVolta := MsgYesNo("Deseja cancelar a altera��o ? Os dados digitados ser�o perdidos.")
	Endif
	
	If lVolta
		
		IF nMode == 2 .or. nMode == 3
			
			// Se eu estava fazendo uma altera��o ou exclus�o,
			// eu devo voltar para o modo de consulta
			
			// Release 1.1
			// Atualiza os dados do registro atual na tela
			ReadRecord(aGets)

			nMode := 4
			AdjustMode(oDlg,aBtns,aGets,nMode)
			
		Else
			
			// Qualquer outro cancelamento, volta ao estado inicial
			nMode := 0
			AdjustMode(oDlg,aBtns,aGets,nMode)
			
		Endif

	Endif
	
ElseIf nAction == 7  // Consulta - Primeiro Registro
	
	DbSelectArea("AGENDA")
	Dbgotop()
	
	// Coloca na tela o conteudo do registro atual
	ReadRecord(aGets)
	
ElseIf nAction == 8  // Consulta - Registro anterior
	
	DbSelectArea("AGENDA")
	DbSkip(-1)
	
	IF BOF()
		// Bateu no in�cio do arquivo
		MsgInfo("N�o h� registro anterior. Voc� est� no primeiro registro da Agenda")
	ELSE
		// Coloca na tela o conteudo do registro atual
		ReadRecord(aGets)
	Endif
	
ElseIf nAction == 9  // Consulta - Pr�ximo Registro
	
	DbSelectArea("AGENDA")
	DbSkip()
	
	IF Eof()

		// Bateu no final do arquivo
		MsgInfo("Nao h� pr�ximo registro. Voc� est� no �ltmo registro da Agenda")

		// Reposiciona no ultimo registro 
		DBgobottom()
		
	Endif
	
	// Coloca na tela o conteudo do registro atual
	ReadRecord(aGets)
	
ElseIf nAction == 10  // Consulta - �ltmio  Registro
	
	DbSelectArea("AGENDA")
	DBGoBottom()
	
	// Coloca na tela o conteudo do registro atual
	ReadRecord(aGets)
	
ElseIf nAction == 11  // Pesquisa Indexada

	// Realiza a busca 
	PesqIndeX(oDlg)

	// Atualiza na tela o conteudo do registro atual 
	ReadRecord(aGets)
	
ElseIf nAction == 12  // Troca de Ordem

	IF ChangeOrd(oDlg)
		// Se a ordem foi trocada 
		// Atualiza texto com a chave do indice em uso 
		oSayOrd:SetText("Ordem .... "+ AGENDA->(IndexKey()))
    Endif
    

Else
	
	UserException("Unexpected Action "+cValToChaR(nAction))
	
Endif

// Atualiza os componentes da tela
oDlg:Refresh()

Return

// -------------------------------------------------
// L� o conteudo do registro atual e alimenta
// os objetos GET na tela
// -------------------------------------------------

STATIC Function ReadRecord(aGets)
Local nI , nT := len(aGets)
Local nPos , cValue
For nI := 1 to nT
	nPos := Fieldpos( aGets[nI][1] )
	cValue := FieldGet(nPos)
	EVAL( aGets[nI][2]:bSetGet, cValue)
Next
Return


// -------------------------------------------------
// Pega os valores dos campos dos GETs da tela
// e atualiza os campos da AGENDA no registro atual
// Observa��o : O registro atualmente posicionado � atualizado,
// e para isso ele deve ser previamente bloqueado ( DBRLOCK  )
// -------------------------------------------------

STATIC Function PutRecord(aGets)
Local nI , nT := len(aGets)
Local nPos , cValue
For nI := 1 to len(aGets)
	cValue := EVAL( aGets[nI][2]:bSetGet )
	nPos := Fieldpos(aGets[nI][1])
	Fieldput(nPos, cValue)
Next
Return

// -------------------------------------------------
// Habilita ou desabilita os not�es de navega��o
// -------------------------------------------------
STATIC Function SetNavBtn(aBtns,lEnable)

Local oPanel := aBtns[7]:oParent
oPanel:SEtEnable(lEnable)
Return


// -------------------------------------------------
// Desabilita os botoes de todas as opera��es
// -------------------------------------------------

STATIC Function DisableOPs(aBtns)
aBtns[1]:Disable() // Inclusao
aBtns[2]:Disable() // Alteracao
aBtns[3]:Disable() // Exclusao
aBtns[4]:Disable() // Consulta / Navega��o
return

// -------------------------------------------------
// Ajusta os controles atuais baseado no modo atual
// -------------------------------------------------
STATIC Function AdjustMode(oDlg,aBtns,aGets,nMode)

If nMode == 0
	
	// Modo inicial 
	// Habilita apenas inclisao e consulta 
	oDlg:CTITLE("CRUD - Agenda")
	
	// Modo incial habilita apenas inclusao e consulta
	// Altera��o e Exclusao somente serao habilitados 
	// quando a interface estiver mostrando um registro 
	
	aBtns[1]:Enable()   // Inclusao
	aBtns[2]:Disable()  // Alteracao
	aBtns[3]:Disable()  // Exclusao
	aBtns[4]:Enable()   // Consulta / Navega��o
	
	// Esconde Confirmar e Voltar
	aBtns[5]:Hide()  // Confirma
	aBtns[6]:Hide()  // Volta
	
	// Esconde botoes de navega��o
	SetNavBtn(aBtns,.F.)
	
	// Limpa todos os valores de tela , desabilitando os GETS
	ClearGets(aGets , .F. )

ElseIf nMode == 1
	
	oDlg:CTITLE("CRUD - Agenda (Inclus�o)")
	
	// Ajusta botoes baseado no modo atual ( Inclusao )
	// Desliga todas as opera��es
	DisableOPs(aBtns)          
	
	// Mostra Confirmar e Voltar
	aBtns[5]:Show() // Confirmar
	aBtns[6]:Show() // Voltar
	
	// Esconde botoes de navega��o
	SetNavBtn(aBtns,.F.)
	
ElseIF  nMode == 2
	
	oDlg:CTITLE("CRUD - Agenda (Altera��o)")
	
	// Ajusta botoes baseado no modo atual ( Altera��o )
	
	// Desliga todas as opera��es
	DisableOPs(aBtns)
	                        
	// Mostra Confirmar e Voltar
	aBtns[5]:Show() // Confirmar
	aBtns[6]:Show() // Voltar
	
	// Esconde botoes de navega��o
	SetNavBtn(aBtns,.F.)
	
ElseIF  nMode == 3
	
	oDlg:CTITLE("CRUD - Agenda (Exclus�o)")
	
	// Ajusta botoes baseado no modo atual ( Exclus�o )

	// Desliga a edi��o dos GETS	
	EnableGets(aGets,.F.)

	// Desliga todas as opera��es
	DisableOPs(aBtns)
	
	// Mostra Confirmar e Voltar
	aBtns[5]:Show() // Confirmar
	aBtns[6]:Show() // Voltar
	
	// Esconde botoes de navega��o
	SetNavBtn(aBtns,.F.)
	
ElseIF  nMode == 4
	
	oDlg:CTITLE("CRUD - Agenda (Consulta)")
	
	// Ajusta botoes baseado no modo atual ( Consulta )
	
	// Desliga a edi��o dos GETS	
	EnableGets(aGets,.F.)
	aBtns[1]:Enable() // Inclusao
	aBtns[2]:Enable() // Alteracao
	aBtns[3]:Enable() // Exclusao
	aBtns[4]:Disable() // Consulta / Navega��o
	
	// Esconde Confirmar e Voltar
	aBtns[5]:Hide() // Confirmar
	aBtns[6]:Hide() // Voltar
	
	// Mostra botoes de navega��o apenas na consulta 
	SetNavBtn(aBtns,.T.)
	
Endif

Return


// Release 1.2
// Usar cache em mem�ria para gerar a sequencia

STATIC Function GetNewID()
Local cLastID,cNewId
Local nRetry := 0
While !GlbNmLock("AGENDA_ID")
	// Espera m�xima de 1 segundo, 20 tentativas
	// com intervalos de 50 milissegundos
	nRetry++
	If nRetry > 20
		return ""
	Endif
	Sleep(50)
Enddo
cLastID := GetGlbValue("AGENDA_SEQ")
If Empty(cLastID)
	// Somente busco na Tabela se eu nao tenho o valor na memoria
	DBSelectArea("AGENDA")
	DbsetOrder(1)
	DBGobottom()
	cLastId := AGENDA->ID
Endif
cNewId := StrZero( val(cLastID) + 1 , 6 )
PutGlbValue("AGENDA_SEQ",cNewID)
GlbNmUnlock("AGENDA_ID")
Return cNewId


// Release 1.1 
// Exemplo de valida��o do campo cUF ( Estado ou Unidade da Federa��o ) 

STATIC Function VldUf(cUF)
If Empty(cUF)
	// Estado nao informado / vazio / em branco 
	Return .T.
Endif
If cUF $ "AC,AL,AP,AM,BA,CE,DF,ES,GO,MA,MT,MS,MG,PA,PB,PR,PE,PI,RJ,RN,RS,RO,RR,SC,SP,SE,TO"
	// Estado digitado est� na lista ? Beleza
	Return .T.
Endif          

// Chegou at� aqui ? O estado informado n�o � v�lido. 
// Mostra a mensagem e retorna .F., nao permitindo 
// que o foco seja removido do campo 
MsgSTop("Unidade da Federa��o inv�lida ou esconhecida : ["+cUF+"] - "+;
        "Informe um valor v�lido ou deixe este campo em branco.","Erro na Valida��o")

Return .F.



Static Function ChangeOrd(oDlg)
Local nOrdAtu := AGENDA->(IndexOrd())
Local nNewOrd := 0
If nOrdAtu == 1 
	If MsgYesNo("Deseja alterar para ordem de NOME ?")
		nNewOrd := 2
	Endif
Else
	If MsgYesNo("Deseja alterar para ordem de ID ?")
		nNewOrd := 1
	Endif
Endif 

if ( nNewOrd > 0 ) 
	AGENDA->(DBSETORDER(nNewOrd))
Endif

return nNewOrd > 0 


STATIC Function PesqIndeX(oDlgParent)
Local oDlgPesq 
Local cTitle
Local cStrBusca
Local nTamanho
Local nRecSave 
Local lFound := .F.
Local cIndexFld := AGENDA->(Indexkey())
Local oGet1 , oBtn1

// Monta titulo da janela de pesquisa
cTitle := 'Pesquisa por '+ cIndexFld

// Guarda numero do registro atual 
nRecSave := AGENDA->(Recno())

If indexord() == 1
	nTamanho := 6
	cStrBusca := space(nTamanho)
	cPicture := "@9"
ElseIf indexord() == 2
	nTamanho := 50
	cStrBusca := space(nTamanho)
	cPicture := "@!"
Endif

DEFINE DIALOG oDlgPesq TITLE (cTitle) ;
	FROM 0,0 TO 120,415 PIXEL;
	OF oDlgParent ; 
	COLOR CLR_BLACK, CLR_LIGHTGRAY 

@ 05,05 GET oGet1 VAR cStrBusca   PICTURE (cPicture)   SIZE CALCSIZEGET(nTamanho) ,12 OF oDlgPesq PIXEL

@ 25,05 BUTTON oBtn1 PROMPT "Buscar" SIZE 60,15 ;
	ACTION IIF( SeekAgenda(cIndexFld,cStrBusca) , (lFound := .T. , oDlgPesq:End()) , oGet1:SetFocus() ) OF oDlgPesq PIXEL

ACTIVATE DIALOG oDlgPesq CENTER

If !lFound
	// Nao achou, volta ao registro antes da busca 
	AGENDA->(dbgoto(nRecSave))
Endif

Return 


STATIC Function SeekAgenda(cIndexFld,cStrBusca)

IF cIndexFld == 'ID'
	cStrBusca := strzero(val(cStrBusca),6)
ElseIF cIndexFld == 'NOME'
	cStrBusca := alltrim(cStrBusca)
Endif

If !DbSeek(cStrBusca)
	MsgStop("Informa��o n�o encontrada.","Busca por ["+cStrBusca+"]")
	return .F.
Endif

return .T. 
