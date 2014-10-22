/******************************************************************************
 *
 *	- MODULO DE VIDEO CONFERENCIA - CLIENTE - SIMPLIFICADO
 *
 ******************************************************************************
 *	@AUTHOR: YURIFIALHO - 2º TEN FIALHO
 *	@SINCE: 15/10/2014
 *
 *******************************************************************************/
import mx.controls.Alert;
import mx.events.FlexEvent;
import mx.events.MoveEvent;
import mx.effects.easing.*;
import mx.managers.SystemManager;
import mx.rpc.events.FaultEvent;
import mx.events.ItemClickEvent;
import mx.collections.ArrayCollection;
import mx.rpc.events.ResultEvent;
import mx.core.FlexGlobals; 
import mx.effects.easing.*;
import flash.net.SharedObject; 

// store the user access level after user logs in
private var userAccess:String = "";
// define roles to compare against
private var roles:String = "failed";

private var timeoutTotal:Number = 0;
private var timeoutLastCall:Number;
public  var timeout:Number = 300000; // timeout after five minutes (300s)
public  var sessionExpired:Boolean = false;
public  var enableTimeout:Boolean = true;
private var user2:String = "";

private var nc:NetConnection;
		
//Stream das webcams dos usuarios para visualização 
private var nsCli:Dictionary  = new Dictionary();
//Stream das webcams dos usuarios para publicação
private var nsPub:Dictionary  = new Dictionary();
private var conectado:Dictionary = new Dictionary();
		
//Canal para o chat;
private var sharedObject:SharedObject;

private var con:int;
private var vidComando:Video = null;
private var ckLogout:int = 0;

private var usuarios:Array = new Array("Cmdo","23bc","25bc", "40bi", "2becnst", "3becnst",
									   "pqmnt10", "10dsup", "cmf", "hgef", "52ct", "25csm",
									   "26csm", "10icfex", "10ciagd", "ciacmdo", "convidado1",
									   "convidado2");

[Bindable]
private var statusConnection:Boolean=false
	
/**
 * Inicia a aplicação e faz a conexão
 */
private function init():void
{
	if ( nc != null )
	  	nc=null;
  
    nc=new NetConnection();
    nc.addEventListener( NetStatusEvent.NET_STATUS, netStatus );
			
	//Endereço do servidor 
	nc.connect( "rtmp://10.100.9.250/fitcDemo" );
    nc.client=this;
	ckLogout = 0;

}

/**
 * Método necessário para que não haja erro na chamada.
 * Ele será invocado e retornará o ID da conexão
 */
public function setId( id:Object ):void
{
}

/**
 * Método que recebe o Status da conexão
 */
private function netStatus( e:NetStatusEvent ):void
{
    RED5Status.text=e.info.code;
    statusConnection=false;
    switch ( e.info.code )
    {
        case "NetConnection.Connect.Success":
		{
			writeMessage("Conectando...");
            statusConnection=true;
			visualizar();  //Ao conectar, já exibe as câmeras dos outros usuários
			//Cria o objeto compartilhado para o chat
			sharedObject=SharedObject.getRemote( "txtChatBox", nc.uri, true );
			sharedObject.connect( nc );
    		sharedObject.client=this;
    		writeMessage("Conectado!");
            break;
		}
        case "NetConnection.Connect.Closed": break;
        case "NetConnection.Connect.Rejected": break;
    }
}


private function publicar():void
{
	writeMessage("Publicando...");
	//Definições de Codec e Qualidade de áudio e vídeo
	var cam:Camera;		
	var mic:Microphone;		

	mic=Microphone.getMicrophone();
	mic.codec="SPEEX";
	mic.encodeQuality=6;
	mic.framesPerPacket=6;

	cam=Camera.getCamera();
	cam.setLoopback(true);
	cam.setMotionLevel(70);
	cam.setQuality(8192,0);		//64 Kbps, compactacao livre dentro da banda disp.

	//Video Local (nao faz download de stream)
	var videoLCamera:Video=new Video();
    videoLCamera.height=videoPrincipal.height;
    videoLCamera.width=videoPrincipal.width;
    videoLCamera.attachCamera( cam ); // AttachCamera e nao AttachNetStream
    videoPrincipal.addChild(videoLCamera);

    for(var i:int=0; i < usuarios.length; i++)
    {
    	if(usuarios[i] == username.text)
    	{
    		//Alert.show("Inicou publicacao: " + usuarios[i]);
    		inciarPublicacao(i);
    		//writeMessage("Publicado.");
    		break;
    	}
    }
}

private function visualizar():void
{
	if ( !statusConnection )
    {
        Alert.show( "Não conectado ao servidor!" );
        writeMessage("Nao conectou.");
        return;
    }
    
    if ( nsCli[0] != null )
    {
		nsCli[0].close();
        delete nsCli[0];
    }
    
	for(var j:int=0; j < usuarios.length; j++)
	{
		if(usuarios[j] == username.text)
		{
			try{
				(getLabelsById("labelU"+j) as Label).enabled = true;
			} catch(e:Error){
				writeMessage("Error:"+e.message);
				Alert.show("Erro: Favor fechar e entrar novamente!");
			}
		}
	}
	
	//Cria as streammings para ver cada usuario
	nsCli[0]=new NetStream(nc);

	vidComando=new Video();
    vidComando.height=videoComando.height;
    vidComando.width =videoComando.width;
    vidComando.attachNetStream(nsCli[0]);
	nsCli[0].addEventListener(NetStatusEvent.NET_STATUS, statusHandler);
	videoComando.addChild(vidComando);
    // Exibe as streammings - do comando
	nsCli[0].play("videoPublish0");
	
	//Executar o audio das outras omds
	for(var k:int = 1; k < usuarios.length; k++) 
	{
		if(username.text != usuarios[k]){
			try 
			{
				nsCli[k]=new NetStream(nc);
				nsCli[k].receiveVideo(false);
				var vid:Video=new Video();
		    	 	vid.height=1;
		    		vid.width=1;
		    		vid.attachNetStream(nsCli[k]);
		    	nsCli[k].addEventListener(NetStatusEvent.NET_STATUS,
		    		function(event:NetStatusEvent):void
		    		{
		    			//writeMessage(event.info.code);
		    			switch(event.info.code){
		    				case "NetStream.Play.PublishNotify":
		    				{
		    					nsCli[k].play("videoPublish"+k);
		    					(getLabelsById("labelU"+k) as Label).enabled = true;
		    					writeMessageAll(usuarios[k]+" Conectou.");		
		    					break;
		    				}
		    				case "NetStream.Play.UnpublishNotify":
		    				{
		    					(getLabelsById("labelU"+k) as Label).enabled = false;
		    					writeMessageAll(usuarios[k]+" Desconectou.");
		    					break;
		    				}
		    			}
		    		});
				(getVideosById("video"+k) as UIComponent).addChild(vid);
				nsCli[k].play("videoPublish"+k);
			} catch(e:Error) {
				writeMessage("Error" + e);
			}
		}

	}
}

public function envia_mensagem( msg:String ):void
{
	msg = "<p><b>" + username.text + ": " + "</b>" + msg + "</p> \n";
	mensagem.text=""; 
	sharedObject.send( "recebemsg", msg );
} 		

public function recebemsg( msg:String ):void 
{
	txtChatBox.htmlText+=msg;
	txtChatBox.validateNow();
	txtChatBox.verticalScrollPosition=txtChatBox.maxVerticalScrollPosition;
}

public function writeMessage(texto:String):void
{
	texto = "<p>" + texto + "</p> \n";
	txtChatBox.htmlText+=texto;
}

public function writeMessageAll(texto:String):void
{
	texto = "<p>" + texto + "</p> \n";
	sharedObject.send( "recebemsg", texto );
}

//////////////////////// INICIAR PUBLICACOES ////////////////////////////////

private function inciarPublicacao(id:int):void
{
	if ( nsPub[id] == null && ckLogout == 0)
    {
	
		btPublicar.label="Parar áudio/vídeo";
		
		nsPub[id]=new NetStream(nc);
		nsPub[id].close();
        delete nsPub[id];

		nsPub[id]=new NetStream(nc);
		nsPub[id].addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);
		nsPub[id].addEventListener(NetStatusEvent.NET_STATUS, statusHandler);
		
		var cam:Camera =Camera.getCamera();
		cam.setLoopback(true);
		cam.setMotionLevel(70);
		cam.setQuality(4192,1);

		nsPub[id].attachCamera(cam);

		var mic:Microphone =Microphone.getMicrophone();
		mic.codec="SPEEX";
		mic.encodeQuality = 2;
		mic.framesPerPacket = 3;
		mic.setSilenceLevel(0);
		mic.setUseEchoSuppression(true);

    nsPub[id].attachAudio(mic);

    // nome que será publicado
    nsPub[id].publish( "videoPublish" + id );
	}
	else
	{
		btPublicar.label="Publicar áudio/vídeo";
				
        nsPub[id].close();
        delete nsPub[id];
	}
}
		
public function asyncErrorHandler(event:AsyncErrorEvent):void 
{ 
	Alert.show("Erro de comunicacao, feche e abra o programa novamente!", "Erro Com", Alert.OK);
}
		
public function statusHandler(event:NetStatusEvent):void 
{ 
	switch (event.info.code) 
	{ 
		case "NetStream.Play.Start": 
			break; 
		case "NetStream.Play.UnpublishNotify":
			vidComando.clear();
			break; 
	}
}

public function getLabelsById(id:String):DisplayObject
{
	for each( var item:Object in labels.getChildren()){
		if(item['id'] == id)
  		{
   			return item as DisplayObject;
  		}
 	}
	return null;
}

public function getVideosById(id:String):DisplayObject
{
	for each( var item:Object in getChildren()){
  		if(item['id'] == id)
  		{
   			return item as DisplayObject;
  		}
 	}
	return null;
}

//////////////////////// LOGIN LOGOUT E TIMEOUT ////////////////////////////////

// we could convert this into a reusable class
// we are not going to for simplicity
private function timeoutHandler(event:FlexEvent):void 
{
	// get current time
	var curTime:int = getTimer();
	var timeDiff:int = 0;
	if (isNaN(timeoutLastCall)) {
		timeoutLastCall = curTime;
	}
	
	timeDiff = curTime - timeoutLastCall;
	timeoutLastCall = curTime;
	
	// if time has passed since the idle event we assume user is interacting
	// reset time total - otherwise increment total idle time
	if (timeDiff > 1000) {
		timeoutTotal = 0;
	}
	else {
		// update time
		// the status field will not be updated unless the application is idle
		// it is only display a countdown for learning purposes
		timeoutTotal += 100;
		//status.text = "Sua sessão expira em " + String(Number((timeout - timeoutTotal)/1000).toFixed(0)) + " segundos";
	}
	
	
	// if the total time of inactivity passes our timeout
	// and the session already hasn't expired then logout user
	if (timeoutTotal > timeout && !sessionExpired) {
		// logout user
		// or set flag

		//sessionExpired = true;
		//status.text = "timeout threshold has been reached";
		//sessionTimeoutHandler();
	}
}
		
// when the application times out due to inactivity we call this function
private function sessionTimeoutHandler():void {
	logout();
	var message:String = "Sua sessão expirou por inatividade!\nPor favor conecte-se novamente";
	Alert.show(message, "Sessão Expirou", Alert.OK);
	// remove idle listener
	var sysMan:SystemManager = FlexGlobals.topLevelApplication.systemManager;
	sysMan.removeEventListener(FlexEvent.IDLE, timeoutHandler);
}

// this is the function that receives a response from the server after clicking submit
// event.result contains the string response from the server
// we check if the user has access to any of the roles
private function handleLogin(event:ResultEvent):void {
	userAccess = event.result as String;
	trace("handleLogin result data = "+userAccess);
	
	if (userAccess.indexOf(roles)>-1) {   //se userAccess for 'failed'
		// show failed login message, show guest menu
		loginFailedText.visible = true;
		//linkBar.dataProvider = guestMenu;
	}
	else {
		// login success
		// hide failed login message, set login form to success state, show user menu
		loginFailedText.visible = false;
		//loginStack.selectedChild = loginSuccess;
		//linkBar.dataProvider = userMenu;
		sessionExpired = false;
		//viewStack.selectedChild = viewStack.parentApplication[String(userMenu.getItemAt(1))];
		var sysMan:SystemManager = FlexGlobals.topLevelApplication.systemManager;
		if (enableTimeout) {
			sysMan.addEventListener(FlexEvent.IDLE, timeoutHandler);
		}
									
		//Espera 1 segundo e oculta o painel de login
			// creates a new five-second Timer
    				var minuteTimer:Timer = new Timer(1000, 1);

			// designates listeners for the interval and completion events
    				//minuteTimer.addEventListener(TimerEvent.TIMER, onTick);
    				minuteTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onTimerComplete);

			// starts the timer ticking
		            minuteTimer.start();

		//Mostra a mensagem de boas vindas
		loginSuccess.visible = true;
		
		tela.visible=true;
		chat.visible=true;

		//Mostra / esconde os painéis de acordo com o nível de acesso								
		switch (userAccess)
		{
			case "2": //leilao
				
			break;

			case "1": //banco
				
			break;

			case "0": //usuario
				
			break;
		}

		//Muda para o estado 'conectado'
		currentState="conectado";
	
		//Inicializa o sistema (vconf)
		//init();
	}

}
		
private function handleLogout(event:ResultEvent):void {
	//textarea1.text = "You have manually destroyed the session. Try to get data from the server.";
}

// handles logging out for other functions
private function logout():void 
{

	//mata a visualização
	nsCli[0].close();
	delete nsCli[0];
	
	ckLogout = 1;
	publicar() //"clica" no botao "parar publicação"

	username.text = "";
	password.text = "";
	painelLogin.visible = true;
	loginSuccess.visible = false;

	//Muda para o estado 'default'
	currentState="default";
	
	//Espera 1 segundo e oculta o painel de login
	// creates a new five-second Timer
	var minuteTimer:Timer = new Timer(1000, 1);

	// designates listeners for the interval and completion events
	//minuteTimer.addEventListener(TimerEvent.TIMER, onTick);
	minuteTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onTimerComplete2);

	// starts the timer ticking
	minuteTimer.start();

	loginFailedText.visible = false;
}
		
private function handleFault(event:FaultEvent):void {
	trace("fault = "+event.message);
}

//////////////////////// LEILAO /////////////////////////////////////
public function onTimerComplete(event:TimerEvent):void
{
    painelLogin.visible=false;
	//Inicializa o sistema (vconf)
	init();
}

public function onTimerComplete2(event:TimerEvent):void
{

	//Fecha as conexoes abertas (PUB)
   	tela.visible=false;
	chat.visible=false;
}

public function teste():void {
	//Muda para o estado 'default'
			currentState="conectado";
}