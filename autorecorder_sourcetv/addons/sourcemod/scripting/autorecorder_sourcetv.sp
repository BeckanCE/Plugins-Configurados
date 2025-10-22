#include <sourcemod>
#include <multicolors>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.5.0-Final"

public Plugin myinfo = 
{
	name = "Auto Recorder (Custom)",
	author = "Stevo.TVR (modificado por Gemini)",
	description = "Automates SourceTV recording based on player count and time of day.",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

ConVar g_hTvEnabled = null;
ConVar g_hAutoRecord = null;
ConVar g_hMinPlayersStart = null;
ConVar g_hIgnoreBots = null;
ConVar g_hTimeStart = null;
ConVar g_hTimeStop = null;
ConVar g_hFinishMap = null;
ConVar g_hDemoPath = null;

bool g_bIsRecording = false;
bool g_bIsManual = false;

int g_iCampaignID = 0;

public void OnPluginStart()
{
	CreateConVar("sm_autorecord_version", PLUGIN_VERSION, "Auto Recorder plugin version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hAutoRecord = CreateConVar("sm_autorecord_enable", "0", "Enable automatic recording", _, true, 0.0, true, 1.0);
	g_hMinPlayersStart = CreateConVar("sm_autorecord_minplayers", "1", "Minimum players on server to start recording", _, true, 0.0);
	g_hIgnoreBots = CreateConVar("sm_autorecord_ignorebots", "1", "Ignore bots in the player count", _, true, 0.0, true, 1.0);
	g_hTimeStart = CreateConVar("sm_autorecord_timestart", "-1", "Hour in the day to start recording (0-23, -1 disables)");
	g_hTimeStop = CreateConVar("sm_autorecord_timestop", "-1", "Hour in the day to stop recording (0-23, -1 disables)");
	g_hFinishMap = CreateConVar("sm_autorecord_finishmap", "1", "If 1, continue recording until the map ends", _, true, 0.0, true, 1.0);
	g_hDemoPath = CreateConVar("sm_autorecord_path", "demos", "Path to store recorded demos");

	AutoExecConfig(true, "autorecorder");

	RegAdminCmd("sm_record", Command_Record, ADMFLAG_KICK, "Starts a SourceTV demo");
	RegAdminCmd("sm_stoprecord", Command_StopRecord, ADMFLAG_KICK, "Stops the current SourceTV demo");

	g_hTvEnabled = FindConVar("tv_enable");

	char sPath[PLATFORM_MAX_PATH];
	g_hDemoPath.GetString(sPath, sizeof(sPath));
	if(!DirExists(sPath))
	{
		InitDirectory(sPath);
	}

	g_hMinPlayersStart.AddChangeHook(OnConVarChanged);
	g_hIgnoreBots.AddChangeHook(OnConVarChanged);
	g_hTimeStart.AddChangeHook(OnConVarChanged);
	g_hTimeStop.AddChangeHook(OnConVarChanged);
	g_hDemoPath.AddChangeHook(OnConVarChanged);

	CreateTimer(300.0, Timer_CheckStatus, _, TIMER_REPEAT);

	StopRecord();
	CheckStatus();
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char [] newValue)
{
	if(convar == g_hDemoPath)
	{
		if(!DirExists(newValue))
		{
			InitDirectory(newValue);
		}
	}
	else
	{
		CheckStatus();
	}
}

// CAMBIO APLICADO: Modificación #1
public void OnMapEnd()
{
	if(g_bIsRecording)
	{
		StopRecord();
		// Ya no se resetea g_bIsManual aquí para que el modo manual persista entre mapas.
	}
}

public void OnClientPutInServer(int client)
{
	CheckStatus();
}

public void OnClientDisconnect_Post(int client)
{
	CheckStatus();
}

public Action Timer_CheckStatus(Handle timer)
{
	CheckStatus();
}

public Action Command_Record(int client, int args)
{
	if(g_bIsRecording)
	{
		CReplyToCommand(client, "<{green}Grabación{default}> {lightgreen}SourceTV {olive}está grabando en este momento.");
		return Plugin_Handled;
	}

	StartRecord();
	g_bIsManual = true;

	CReplyToCommand(client, "<{green}Grabación{default}> {lightgreen}SourceTV {olive}empezo a grabar.");

	return Plugin_Handled;
}

// CAMBIO APLICADO: Modificación #2
public Action Command_StopRecord(int client, int args)
{
	if(!g_bIsRecording)
	{
		CReplyToCommand(client, "<{green}Grabación{default}> {lightgreen}SourceTV {olive}no esta grabando en este momento.");
		return Plugin_Handled;
	}

	StopRecord();

	// Este comando ahora resetea todo el estado de grabación manual.
	g_iCampaignID = 0;   // Resetea el ID de la campaña.
	g_bIsManual = false;   // Desactiva el modo manual.

	CReplyToCommand(client, "<{green}Grabación{default}> {lightgreen}SourceTV {olive}dejo de grabar. El modo automático está activo.");

	return Plugin_Handled;
}

// CAMBIO APLICADO: Modificación #3
void CheckStatus()
{
	// Si estamos en modo manual y la grabación no está activa (porque el mapa anterior terminó),
	// volvemos a iniciar la grabación para el nuevo capítulo.
	if (g_bIsManual)
	{
		if (!g_bIsRecording)
		{
			StartRecord();
		}
		return; // Salimos para ignorar la lógica de grabación automática.
	}

	if(g_hAutoRecord.BoolValue)
	{
		int iMinClients = g_hMinPlayersStart.IntValue;
		int iPlayers = GetPlayerCount();

		int iTimeStart = g_hTimeStart.IntValue;
		int iTimeStop = g_hTimeStop.IntValue;
		bool bReverseTimes = (iTimeStart > iTimeStop);

		char sCurrentTime[4];
		FormatTime(sCurrentTime, sizeof(sCurrentTime), "%H", GetTime());
		int iCurrentTime = StringToInt(sCurrentTime);

		if(iPlayers >= iMinClients && (iTimeStart < 0 || (iCurrentTime >= iTimeStart && (bReverseTimes || iCurrentTime < iTimeStop))))
		{
			StartRecord();
		}
		else if(g_bIsRecording && !g_hFinishMap.BoolValue && (iPlayers < iMinClients || (iTimeStop >= 0 && iCurrentTime >= iTimeStop)))
		{
			StopRecord();
			g_iCampaignID = 0;
		}
	}
}

int GetPlayerCount()
{
	bool bIgnoreBots = g_hIgnoreBots.BoolValue;

	int iNumPlayers = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsClientConnected(i) && (!bIgnoreBots || !IsFakeClient(i)))
		{
			iNumPlayers++;
		}
	}

	return iNumPlayers;
}

void StartRecord()
{
	if(g_hTvEnabled.BoolValue && !g_bIsRecording)
	{
		char sPath[PLATFORM_MAX_PATH];
		char sMap[64];

		if (g_iCampaignID == 0)
		{
			g_iCampaignID = GetRandomInt(100000, 999999);
		}

		g_hDemoPath.GetString(sPath, sizeof(sPath));
		GetCurrentMap(sMap, sizeof(sMap));

		ReplaceString(sMap, sizeof(sMap), "/", "-", false); 		

		ServerCommand("tv_record \"%s/%s-%d\"", sPath, sMap, g_iCampaignID);
		g_bIsRecording = true;

		LogMessage("Empezo la grabación de %s-%d.dem", sMap, g_iCampaignID);
	}
}

void StopRecord()
{
	if(g_hTvEnabled.BoolValue)
	{
		ServerCommand("tv_stoprecord");
		g_bIsRecording = false;
	}
}

void InitDirectory(const char[] sDir)
{
	char sPieces[32][PLATFORM_MAX_PATH];
	char sPath[PLATFORM_MAX_PATH];
	int iNumPieces = ExplodeString(sDir, "/", sPieces, sizeof(sPieces), sizeof(sPieces[]));

	strcopy(sPath, sizeof(sPath), "");
	for(int i = 0; i < iNumPieces; i++)
	{
		if (i > 0)
		{
			StrCat(sPath, sizeof(sPath), "/");
		}
		StrCat(sPath, sizeof(sPath), sPieces[i]);
		if(!DirExists(sPath))
		{
			CreateDirectory(sPath, 509);
		}
	}
}