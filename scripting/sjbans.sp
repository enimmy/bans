#include <sourcemod>
#include <ripext>

#pragma newdecls required
#pragma semicolon 1

#define URL "https://sourcejump.net/api/players/banned"

ArrayList gA_SteamIds;
bool gB_TimerBanned[MAXPLAYERS + 1];
bool g_bLate = false;

public Plugin myinfo =
{
	name = "SourceJump Bans",
	author = "Eric",
	description = "Checks if connecting clients are SourceJump banned.",
	version = "1.0.0",
	url = "https://steamcommunity.com/id/-eric"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLate = late;
	CreateNative("SJ_IsBanned", Native_IsSjBanned);
	RegPluginLibrary("sjbans");
	return APLRes_Success;
}

public void OnPluginStart()
{
	gA_SteamIds = new ArrayList(ByteCountToCells(32));

	if(g_bLate)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(!IsClientConnected(i) || !IsClientInGame(i) || IsFakeClient(i) || !IsClientAuthorized(i))
			{
				continue;
			}
			OnClientPostAdminCheck(i);
		}
	}
}

public void OnConfigsExecuted()
{
	HTTPRequest request = new HTTPRequest(URL);
	request.SetHeader("api-key", "SJPublicAPIKey");
	request.Get(OnBannedPlayersReceived);
}

public void OnClientPostAdminCheck(int client)
{
	if(IsFakeClient(client))
	{
		return;
	}

	if(!RefreshClientStatus(client))
	{
		CreateTimer(0.5, Auth_Timer, client, TIMER_REPEAT);
	}
}

Action Auth_Timer(Handle timer, int client)
{
	if(RefreshClientStatus(client))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

bool RefreshClientStatus(int client)
{
	gB_TimerBanned[client] = true;

	char steamId[32];

	if(!GetClientAuthId(client, AuthId_Steam3, steamId, sizeof(steamId)))
	{
		return false;
	}

	if (gA_SteamIds.FindString(steamId) == -1)
	{
		gB_TimerBanned[client] = false;
	}
	return true;
}

void OnBannedPlayersReceived(HTTPResponse response, any value)
{
	if (response.Status != HTTPStatus_OK)
	{
		LogError("Failed to retrieve banned players. Response status: %d.", response.Status);
		return;
	}

	if (response.Data == null)
	{
		LogError("Invalid response data.");
		return;
	}

	gA_SteamIds.Clear();

	JSONArray players = view_as<JSONArray>(response.Data);
	JSONObject player;
	char steamId[32];

	for (int i = 0; i < players.Length; i++)
	{
		player = view_as<JSONObject>(players.Get(i));
		player.GetString("steamid", steamId, sizeof(steamId));

		gA_SteamIds.PushString(steamId);

		delete player;
	}

	delete players;
}

int Native_IsSjBanned(Handle plugin, int params)
{
	return gB_TimerBanned[GetNativeCell(1)];
}
