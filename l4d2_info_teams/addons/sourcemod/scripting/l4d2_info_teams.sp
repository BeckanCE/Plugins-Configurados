#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <readyup>
#include <multicolors>

#define PLUGIN_VERSION "1.5-mod"

ConVar g_hReadyCfgName;

public Plugin myinfo = 
{
    name = "[L4D2] Mostrar información al inicio de cada ronda",
    author = "Beckan (modificado por ChatGPT)",
    description = "Muestra los equipos, mapa, espectadores y configuración cuando comienza la ronda.",
    version = PLUGIN_VERSION,
    url = ""
};

public void OnPluginStart()
{
    PrintToServer("[Team Info Plugin] Loaded. Version: %s", PLUGIN_VERSION);
    g_hReadyCfgName = FindConVar("l4d_ready_cfg_name");
}

public void OnRoundIsLive()
{
    char survivorNames[512];
    char infectedNames[512];
    survivorNames[0] = '\0';
    infectedNames[0] = '\0';

    char mapName[64];
    GetCurrentMap(mapName, sizeof(mapName));

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i)) 
            continue;

        char playerName[64];
        GetClientName(i, playerName, sizeof(playerName));

        if (strncmp(playerName, "(S) ", 4) == 0 || strncmp(playerName, "(S)", 3) == 0 ||
            strncmp(playerName, "(C) ", 4) == 0 || strncmp(playerName, "(C)", 3) == 0)
        {
            continue;
        }

        int team = GetClientTeam(i);

        if (team == 2)  // Supervivientes
        {
            if (strlen(survivorNames) > 0)
                StrCat(survivorNames, sizeof(survivorNames), "\x01, ");
            
            StrCat(survivorNames, sizeof(survivorNames), "\x03");
            StrCat(survivorNames, sizeof(survivorNames), playerName);
        }
        else if (team == 3)  // Infectados
        {
            if (strlen(infectedNames) > 0)
                StrCat(infectedNames, sizeof(infectedNames), "\x01, ");

            StrCat(infectedNames, sizeof(infectedNames), "\x03");
            StrCat(infectedNames, sizeof(infectedNames), playerName);
        }
    }

    CPrintToChatAll("{green}> {olive}Mapa{default}: {green}%s", mapName);
    CPrintToChatAll("{green}> {olive}Supervivientes{default}: {blue}%s", survivorNames);
    CPrintToChatAll("{green}> {olive}Infectados{default}: {red}%s", infectedNames);

    char spectatorsAndCasters[512];
    spectatorsAndCasters[0] = '\0';

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i)) 
            continue;

        char playerName[64];
        GetClientName(i, playerName, sizeof(playerName));

        if (strncmp(playerName, "(S) ", 4) == 0 || strncmp(playerName, "(S)", 3) == 0 ||
            strncmp(playerName, "(C) ", 4) == 0 || strncmp(playerName, "(C)", 3) == 0)
        {
            if (strlen(spectatorsAndCasters) > 0)
                StrCat(spectatorsAndCasters, sizeof(spectatorsAndCasters), " \x01- ");
            
            StrCat(spectatorsAndCasters, sizeof(spectatorsAndCasters), "\x05");
            StrCat(spectatorsAndCasters, sizeof(spectatorsAndCasters), playerName);
        }
    }

    if (strlen(spectatorsAndCasters) > 0)
    {
        CPrintToChatAll("{green}> {olive}Espectadores{default}: {olive}%s", spectatorsAndCasters);
    }

    // Obtener y mostrar el valor actual de la configuración
    char cfgName[64];
    if (g_hReadyCfgName != null)
    {
        g_hReadyCfgName.GetString(cfgName, sizeof(cfgName));
    }
    else
    {
        strcopy(cfgName, sizeof(cfgName), "desconocida");
    }

    CPrintToChatAll("{green}> {olive}Configuración{default}: {green}%s", cfgName);
}
