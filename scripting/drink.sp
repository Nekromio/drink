#include <colors_ws>

bool
	bDrink[MAXPLAYERS+1];

float
	fLastUsed[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "Drink/Выпить",
	author = "Nek.'a 2x2 | ggwp.site ",
	description = "Позволяет выпивать на сервере !",
	version = "1.0.1",
	url = "https://ggwp.site/"
};

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	//HookUserMessage(GetUserMessageId("SayText2"), SayText2, true);
	HookUserMessage(GetUserMessageId("TextMsg"), UserMessageHook, true); 
	
	RegConsoleCmd("say", CheckText);
	RegConsoleCmd("say2", CheckText);
	RegConsoleCmd("say_team", CheckText);
}

public void OnClientDisconnect(int client)
{
	fLastUsed[client] = 0.0;
	bDrink[client] = false;
}

public void Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	fLastUsed[client] = 0.0;
	bDrink[client] = false;
}

public void OnClientPutInServer(int client)
{
	CreateTimer(40.0, TimerAnnounce, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

Action TimerAnnounce(Handle timer, any userid) 
{
	int client = GetClientOfUserId(userid);
	if(client > 0 && IsClientConnected(client) && IsClientInGame(client)) 
	{
		CPrint(client, _, "{#cc0066}Накатить: {#ff0000}в чат {#ff6600}выпить {#0066ff}или {#ff6600}drink", client);
		CPrint(client, _, "{#009933}Протрезветь: {#0099ff}зукусить {#ff6600}или {#0099ff}eat");
		return Plugin_Continue; 
	}
	return Plugin_Stop; 
}

Action CheckText(int client, any args)
{
	char sBuffer[256], sCmd[256];
	int iStartidx;
	
	if(!client)
		return Plugin_Continue;
	
	if(fLastUsed[client] > GetGameTime() - 1.3)
		return Plugin_Continue;
		
	if(GetCmdArgString(sBuffer, sizeof(sBuffer)) < 1)
		return Plugin_Continue;
		
	if(!IsPlayerAlive(client))
		return Plugin_Continue;
	
	if(sBuffer[strlen(sBuffer)-1] == '"')
	{
		sBuffer[strlen(sBuffer)-1] = '\0';
		iStartidx = 1;
	}
	
	GetCmdArg(0, sCmd, sizeof(sCmd));
	if (strcmp(sCmd, "say2", false) == 0)
		iStartidx += 4;
	
	fLastUsed[client] = GetGameTime();
	
	if(strcmp(sBuffer[iStartidx], "выпить", false) == 0 || strcmp(sBuffer[iStartidx], "drink", false) == 0)
	{
		if(!bDrink[client])
		{
			bDrink[client] = true;
			for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i)) CPrint(i, _, "{#cc0066}Игрок {#ff6600}[{#ff0000}%N{#ff6600}] {#ff6600}выпил рюмашку !", client);
			
			ServerCommand("sm_drug #%d", GetClientUserId(client));
			return Plugin_Continue;
		}
		else
		{
			int rnd = GetRandomInt(0, 4);
			
			switch(rnd)
			{
				case 0: for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i)) CPrint(i, _, "{#cc0066}Игрок {#ff6600}[{#ff0000}%N{#ff6600}] {#ff6600}накатил ещё !", client);
				case 1: for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i)) CPrint(i, _, "{#cc0066}Игрок {#ff6600}[{#ff0000}%N{#ff6600}] {#ff6600}отпил пивка !", client);
				case 2: for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i)) CPrint(i, _, "{#cc0066}Игрок {#ff6600}[{#ff0000}%N{#ff6600}] {#ff6600}шлифанул винца !", client);
				case 3: for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i)) CPrint(i, _, "{#cc0066}Игрок {#ff6600}[{#ff0000}%N{#ff6600}] {#ff6600}опрокинул ещё рюмашку !", client);
				case 4: for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i)) CPrint(i, _, "{#cc0066}Игрок {#ff6600}[{#ff0000}%N{#ff6600}] {#ff6600} ещё.. стакашик.. !", client);
			}
		}
	}
	else if(strcmp(sBuffer[iStartidx], "закусить", false) == 0 || strcmp(sBuffer[iStartidx], "eat", false) == 0)
	{
		if(bDrink[client])
		{
			bDrink[client] = false;
			for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i)) CPrint(i, _, "{#cc0066}Игрок {#ff6600}[{#ff0000}%N{#ff6600}] {#ff6600}закусил и протрезвел !", client);
			ServerCommand("sm_drug #%d", GetClientUserId(client));
			return Plugin_Continue;
		}
		else
		{
			for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i)) CPrint(i, _, "{#cc0066}Игрок {#ff6600}[{#ff0000}%N{#ff6600}] {#ff6600} уже трезв, но жрёт закусь !", client);
		}
	}
	return Plugin_Continue;
}

public Action UserMessageHook(UserMsg MsgId, Handle hBitBuffer, const char[] iPlayers, int iNumPlayers, bool bReliable, bool bInit)
{
	
	BfReadByte(hBitBuffer); 
	BfReadByte(hBitBuffer); 
	char strMessage[256]; 
	BfReadString(hBitBuffer, strMessage, sizeof(strMessage));
	
	if(StrContains(strMessage, "опьянен.") != -1)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}