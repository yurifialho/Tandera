import mx.controls.Alert;
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
		private var nsCli:Dictionary = new Dictionary();
		
		private var vid:Dictionary = new Dictionary();

		//Stream das webcams dos usuarios para publicação
		private var nsPub:NetStream = null;
		
		//Canal para o chat;
		private var sharedObject:SharedObject;

		private var con:int;
		private var ckLogout:int = 0;

    [Bindable]
    private var statusConnection:Boolean=false

    /**
     * Inicia a aplicação e faz a conexão
     */
    private function init():void
    {
	    	if ( nc == null )
				{
        	nc=new NetConnection();
        	nc.addEventListener( NetStatusEvent.NET_STATUS, netStatus );
				}
				//Endereço do servidor 
        nc.connect( "rtmp://10.100.9.250/fitcDemo" );
        nc.client=this;
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
      statusConnection=false
      switch ( e.info.code )
      {
      	case "NetConnection.Connect.Success":
					{
          	statusConnection=true;
						visualizar();  //Ao conectar, já exibe as câmeras dos outros usuários
						//Cria o objeto compartilhado para o chat
						sharedObject=SharedObject.getRemote( "txtChatBox", nc.uri, true )
			      sharedObject.connect( nc );
        		sharedObject.client=this;
            break;
					}
        case "NetConnection.Connect.Closed":   break;
        case "NetConnection.Connect.Rejected": break;
       }
     }


		private function publicar():void
		{
			//Definições de Codec e Qualidade de áudio e vídeo
			var cam:Camera;		
			var mic:Microphone;		

			mic=Microphone.getMicrophone();
			mic.codec="SPEEX";            //Codec para voz padrão voip (nao é bom para radio on-line)
			mic.encodeQuality=4;
			mic.framesPerPacket=1;
		
			cam=Camera.getCamera();
			cam.setLoopback(false);
			cam.setMotionLevel(70);
			cam.setQuality(8192,0);		//64 Kbps, compactacao livre dentro da banda disp.

			if (username.text == "Cmdo")
			{
				
				if(vid[0] != null)
				{
					vid[0].clear();
				}
				
				delete vid[0];
				//Video Local (nao faz download de stream)
				vid[0] = new Video();
	      vid[0].height=video0.height;
	      vid[0].width=video0.width;
	      vid[0].attachCamera( cam ); // AttachCamera e nao AttachNetStream
	      video0.addChild(vid[0]);
				
			} else {
				Alert.show("Usuario nao autorizado a acessar essa funcao");
			}
			
			if(username.text == "Cmdo") {
				con = 0;
				inciarPublicacao(con);
			}
			else
			{
				Alert.show("Usuário desconhecido!");
				return;
			}
		}
		
		private function inciarPublicacao(id:int):void
		{

			if ( nsPub == null && ckLogout == 0)
      {

          btPublicar.label="Parar áudio/vídeo";

					nsPub=new NetStream(nc);

					nsPub.close();
          nsPub = null;

					nsPub=new NetStream(nc);
					nsPub.attachCamera( Camera.getCamera());
          nsPub.attachAudio(Microphone.getMicrophone());

          // nome que será publicado
          nsPub.publish( "videoPublish" + id );
      }
			else
			{
				btPublicar.label="Publicar áudio/vídeo";

        nsPub.close();
        nsPub = null;
			}
		}
		
		private function visualizar():void
    {
        if ( !statusConnection )
        {
            Alert.show( "Não conectado ao servidor!" )
            return;
        }
				
				exibirVideoRemoto(1,  video1);
				exibirVideoRemoto(2,  video2);
				exibirVideoRemoto(3,  video3);
				exibirVideoRemoto(4,  video4);
				exibirVideoRemoto(5,  video5);
				exibirVideoRemoto(6,  video6);
				exibirVideoRemoto(7,  video7);
				exibirVideoRemoto(8,  video8);
				exibirVideoRemoto(9,  video9);
				exibirVideoRemoto(10, video10);
				exibirVideoRemoto(11, video11);
				exibirVideoRemoto(12, video12);
				exibirVideoRemoto(13, video13);
				exibirVideoRemoto(14, video14);
				exibirVideoRemoto(15, video15);
				exibirVideoRemoto(16, video16);
				exibirVideoRemoto(17, video17);
		}
		
		private function exibirVideoRemoto(id:int, video:UIComponent):void
		{
			var inicial:int = 0;
			if(nsCli[id] == null) {
				nsCli[id] = new NetStream(nc);
				inicial = 1;
			}
			
			if(vid[id] != null) {
				vid[id].clear();
			}
			delete vid[id];
			vid[id] = new Video();
			vid[id].height = video.height;
			vid[id].width  = video.width;
			vid[id].attachNetStream(nsCli[id]);
			if(inicial == 1) {
				nsCli[id].addEventListener(NetStatusEvent.NET_STATUS, 
					function(event:NetStatusEvent):void
					{
						switch (event.info.code) 
						{ 
							case "NetStream.Play.UnpublishNotify":
							{
								vid[id].clear();
								
								break;
							}
							case "NetStream.Play.PublishNotify":
							{
								exibirVideoRemoto(id, video);
								
							}
						}
					}
					);
			}
			video.addChild(vid[id]);
			nsCli[id].play( "videoPublish" + id );

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

		//////////////////////// LOGIN LOGOUT E TIMEOUT ////////////////////////////////
		
		// we could convert this into a reusable class
		// we are not going to for simplicity
		private function timeoutHandler(event:FlexEvent):void {
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
				chat.visible=false;

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
				ckLogout = 0;
				//Inicializa o sistema (vconf)
				//init();
			}

		}
		
		private function handleLogout(event:ResultEvent):void {
			//colocar aqui todos os procedimentos de logout

		}
		
		private function exibirChat():void {
			if(chat.visible) {
				chat.visible=false;
			} else {
				chat.visible=true;
			}
		}

		// handles logging out for other functions
		private function logout():void {

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
			// for stream error 2032 see http://www.judahfrangipane.com/blog/?p=87
			trace("fault = "+event.message);
			//loginStack.selectedChild = loginForm;
	//		errorText.visible = true;
	//		errorText.text = "Could not connect to the server. Check the url. \nFault " + event.fault;
			//linkBar.dataProvider = guestMenu;
			//viewStack.selectedChild = viewStack.parentApplication[guestMenu[0]];
		}
		
		public function handleStreamEvent(event:NetStatusEvent):void
		{
					Alert.show(event.toString());
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


