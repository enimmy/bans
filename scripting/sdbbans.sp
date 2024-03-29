#include <sourcemod>
#include <ripext>
#include <steamworks>

bool g_bBannedClients[MAXPLAYERS + 1];
bool g_bLate = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLate = late;
	CreateNative("SDB_IsBanned", Native_IsSDBBanned);
	RegPluginLibrary("sdbbans");
	return APLRes_Success;
}

public void OnPluginStart()
{

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
	g_bBannedClients[client] = false;

	char url[512];
	char id[256];

	if(!GetClientAuthId(client, AuthId_SteamID64, id, sizeof(id)))
	{
		return false;
	}
	Format(url, sizeof(url), "https://api.strafedb.net/players/%s", id);

	HTTPRequest req = new HTTPRequest(url);
	req.Get(RequestHandler, client);
	return true;
}

void RequestHandler(HTTPResponse response, int client)
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

	JSONObject player = view_as<JSONObject>(response.Data);

	char banValue[64];
	player.GetString("banned", banValue, sizeof(banValue));

	if(strcmp(banValue, "true") == 0)
	{
		g_bBannedClients[client] = true;
	}

	delete player;
}

int Native_IsSDBBanned(Handle plugin, any params)
{
	return g_bBannedClients[GetNativeCell(1)];
}