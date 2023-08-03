#pragma semicolon 1
#pragma newdecls required

#include <colors_ws>
#include <sdktools_functions>

enum
{
	G_Unknown,
	G_CSS_34,
	G_CSS_OB,
	G_CSGO
};

Handle
	hTimerDrink[MAXPLAYERS+1];

bool
	bDrink[MAXPLAYERS+1];

int
	iGame;

float
	fLastUsed[MAXPLAYERS+1];

char
	sMsg[256];

public Plugin myinfo =
{
	name = "Drink/Выпить",
	author = "Nek.'a 2x2 | ggwp.site ",
	description = "Позволяет выпивать на сервере !",
	version = "1.0.8",
	url = "https://ggwp.site/"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	switch(GetEngineVersion())
	{
		case Engine_SourceSDK2006:	iGame = G_CSS_34;
		case Engine_CSS:			iGame = G_CSS_OB;
		case Engine_CSGO:			iGame = G_CSGO;
		default:
		{
			FormatEx(error, err_max, "Game is not supported!");
			return APLRes_Success;
		}
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	MsgHook fUserMsgHook = UserMessageHook_Bf;
	switch(iGame)
	{
		case G_CSS_34:	LoadTranslations("drink_css34");
		case G_CSS_OB:	LoadTranslations("drink_css");
		case G_CSGO:
		{
			LoadTranslations("drink_csgo");
			fUserMsgHook = UserMessageHook_Pb;
		}
	}

	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);

	HookUserMessage(GetUserMessageId("TextMsg"), fUserMsgHook, true);

	CreateTimer(40.0, Timer_Announce, TIMER_REPEAT);
}

public void OnClientDisconnect(int client)
{
	ResetStatus(client);
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client;
	if(!(client = GetClientOfUserId(GetEventInt(event, "userid"))))
		return;

	ResetStatus(client);
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client;
	if(!(client = GetClientOfUserId(GetEventInt(event, "userid"))))
		return;

	ResetStatus(client);
}

stock void ResetStatus(int client)
{
	if(bDrink[client])
	{
		if(hTimerDrink[client])
			delete hTimerDrink[client];
		DrinkClient(client, false);
	}

	fLastUsed[client] = 0.0;
	bDrink[client] = false;
}

Action Timer_Announce(Handle timer)
{
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i))
	{
		CPrint(i, "Tag", "%t", "Tag", "Annonce");
		CPrint(i, "Tag", "%t", "Tag", "Annonce two");
	}
	return Plugin_Continue;
}

public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
	if(!IsClientValide(client) || IsFakeClient(client) || !IsPlayerAlive(client))
		return;

	float time = GetGameTime();
	if(fLastUsed[client] + 1.3 > time)
		return;

	fLastUsed[client] = time;
	static char sText[254];
	strcopy(sText, sizeof(sText), sArgs);
	TrimString(sText);
	StripQuotes(sText);

	if(!strcmp(sText, "выпить", false) || !strcmp(sText, "drink", false))
	{
		if(!bDrink[client])
		{
			bDrink[client] = true;
			SayTesxt(client, "Drink first");
			//ServerCommand("sm_drug #%d", GetClientUserId(client));
			hTimerDrink[client] = CreateTimer(1.0, Timer_DrinkClient, GetClientUserId(client), TIMER_REPEAT);
		}
		else
		{
			FormatEx(sText, sizeof(sText), "Drink #%i", GetRandomInt(1, 5));
			SayTesxt(client, sText);
		}
	}
	else if(!strcmp(sText, "закусить", false) || !strcmp(sText, "eat", false))
	{
		if(bDrink[client])
		{
			bDrink[client] = false;
			SayTesxt(client, "Food");
			
			if(hTimerDrink[client])
				delete hTimerDrink[client];
			DrinkClient(client, false);
		}
		else SayTesxt(client, "Eats a snack");
	}
}

Action UserMessageHook_Bf(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	msg.ReadByte();
	msg.ReadString(sMsg, sizeof(sMsg));
	return CheckMessage() ? Plugin_Handled : Plugin_Continue;
}

Action UserMessageHook_Pb(UserMsg msg_id, Protobuf msg, const int[] players, int playersNum, bool reliable, bool init)
{
	msg.ReadString("params", sMsg, sizeof(sMsg), 0);
	return CheckMessage() ? Plugin_Handled : Plugin_Continue;
}

stock bool CheckMessage()
{
	return StrContains(sMsg, "опьянен.") != -1;
}

static void SayTesxt(int client, char[] text)
{
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i))
		CPrint(i, "Tag", "%t", "Tag", text, client);
}

Action Timer_DrinkClient(Handle timer, int UserID) 
{
	int client = GetClientOfUserId(UserID);
	
	if(!IsClientValide(client) || IsFakeClient(client))
		return Plugin_Continue;
	
	DrinkClient(client, true);

	return Plugin_Continue;
}

stock void DrinkClient(int client, bool intoxicate) 
{
	int color[4];
	color[3] = 255;
	color[0] = GetRandomInt(0, 255);
	color[1] = GetRandomInt(0, 255);
	color[2] = GetRandomInt(0, 255);
	
	float fAng[3];
	GetClientEyeAngles(client, fAng);	

	int clients[2];
	clients[0] = client;
	Handle hMessage = StartMessage("Fade", clients[0], 1);
	if(intoxicate)
	{
		if(GetUserMessageType() == UM_Protobuf) 
		{
			PbSetInt(hMessage, "duration", 1000);
			PbSetInt(hMessage, "hold_time", 0);
			PbSetInt(hMessage, "flags", 0x0001);
			PbSetColor(hMessage, "clr", color);
		}
		else
		{
			BfWriteShort(hMessage, 1000);
			BfWriteShort(hMessage, 0);
			BfWriteShort(hMessage, (0x0001));
			BfWriteByte(hMessage, color[0]);
			BfWriteByte(hMessage, color[1]);
			BfWriteByte(hMessage, color[2]);
			BfWriteByte(hMessage, color[3]);
		}

		fAng[0] += GetRandomFloat(-37.0, 37.0);
		fAng[1] += GetRandomFloat(-37.0, 37.0);
		fAng[2] += GetRandomFloat(-90.0, 90.0);
		TeleportEntity(client, NULL_VECTOR, fAng, NULL_VECTOR);
	}
	else
	{
		if(GetUserMessageType() == UM_Protobuf) 
		{
			PbSetInt(hMessage, "duration", 1536);
			PbSetInt(hMessage, "hold_time", 1536);
			PbSetInt(hMessage, "flags", 0x0001);
			PbSetColor(hMessage, "clr", { 0, 0, 0, 0 });
		}
		else
		{
			BfWriteShort(hMessage, 1536);
			BfWriteShort(hMessage, 1536);
			BfWriteShort(hMessage, (0x0001));
			BfWriteByte(hMessage, 0);
			BfWriteByte(hMessage, 0);
			BfWriteByte(hMessage, 0);
			BfWriteByte(hMessage, 0);
		}
		fAng[2] = 0.0;
		TeleportEntity(client, NULL_VECTOR, fAng, NULL_VECTOR);
	}
	
	EndMessage();
}

bool IsClientValide(int client)
{
	return 0 < client <= MaxClients && IsClientInGame(client);
}