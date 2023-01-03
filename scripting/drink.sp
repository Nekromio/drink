#include <colors_ws>

bool
	bDrink[MAXPLAYERS+1];

float
	fLastUsed[MAXPLAYERS+1];

int
	Engine_Version,
	game[4] = {0,1,2,3};		//0-UNDEFINED|1-css34|2-css|3-csgo
	
int GetCSGame()
{
	if (GetFeatureStatus(FeatureType_Native, "GetEngineVersion") == FeatureStatus_Available) 
	{
		switch (GetEngineVersion())
		{
			case Engine_SourceSDK2006: return game[1];
			case Engine_CSS: return game[2];
			case Engine_CSGO: return game[3];
		}
	}
	return game[0];
}

Plugin myinfo =
{
	name = "Drink/Выпить",
	author = "Nek.'a 2x2 | ggwp.site ",
	description = "Позволяет выпивать на сервере !",
	version = "1.0.4",
	url = "https://ggwp.site/"
};

public APLRes AskPluginLoad2()
{
	Engine_Version = GetCSGame();
	if(Engine_Version == game[0])
		SetFailState("Game is not supported!");
		
	return APLRes_Success;
}

public void OnPluginStart()
{
	switch(Engine_Version)
	{
		case 0: LoadTranslations("drink_css34");
		case 1: LoadTranslations("drink_css");
		case 2: LoadTranslations("drink_csgo");
	}
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookUserMessage(GetUserMessageId("TextMsg"), UserMessageHook, true); 
}

public void OnClientDisconnect(int client)
{
	fLastUsed[client] = 0.0;
	bDrink[client] = false;
}

void Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
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
		CPrint(client, "Tag", "%t", "Tag", "Annonce");
		CPrint(client, "Tag", "%t", "Tag", "Annonce two");
		return Plugin_Continue; 
	}
	return Plugin_Stop; 
}

public void OnClientSayCommand_Post(client, const String:command[], const String: sArgs[])
{
	if(client != 0 && !IsFakeClient(client) && IsClientInGame(client) && !(fLastUsed[client] > GetGameTime() - 1.3) && IsPlayerAlive(client))
	{
		fLastUsed[client] = GetGameTime();
		char sText[254];
		strcopy(sText, sizeof(sText), sArgs);
		TrimString(sText);
		StripQuotes(sText);

		if(strcmp(sText, "выпить", false) == 0 || strcmp(sText, "drink", false) == 0)
		{
			if(!bDrink[client])
			{
				bDrink[client] = true;
				SayTesxt(client, "Drink first");
				ServerCommand("sm_drug #%d", GetClientUserId(client));
			}
			else
			{
				FormatEx(sText, sizeof(sText), "Drink #%i", GetRandomInt(0, 4));
				SayTesxt(client, sText);
			}
		}
		else if(strcmp(sText, "закусить", false) == 0 || strcmp(sText, "eat", false) == 0)
		{
			if(bDrink[client])
			{
				bDrink[client] = false;
				SayTesxt(client, "Food");
				ServerCommand("sm_drug #%d", GetClientUserId(client));
			}
			else
			{
				SayTesxt(client, "Eats a snack");
			}
		}
}

Action UserMessageHook(UserMsg MsgId, Handle hBitBuffer, const int[] iPlayers, int iNumPlayers, bool bReliable, bool bInit)
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

void SayTesxt(int client, char[] text)
{
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i))
		CPrint(i, "Tag", "%t", "Tag", text, client);
}