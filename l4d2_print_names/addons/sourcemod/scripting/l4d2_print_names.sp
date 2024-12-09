#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <readyup>
#include <colors>

#define PLUGIN_VERSION "1.2"

public Plugin myinfo = 
{
    name = "[L4D2] Team Info on Ready-Up to Live",
    author = "Beckan",
    description = "Prints Survivor and Infected team members and map info when transitioning from Ready-Up to Live.",
    version = PLUGIN_VERSION,
    url = ""
};

public void OnPluginStart()
{
    PrintToServer("[Team Info Plugin] Loaded. Version: %s", PLUGIN_VERSION);
}

// Evento llamado al cambiar de estado Ready-Up a Live
public void OnRoundIsLive()
{
    char survivorNames[512];
    char infectedNames[512];
    survivorNames[0] = '\0';  // Vaciar las cadenas al inicio
    infectedNames[0] = '\0';

    // Obtener el nombre del mapa actual
    char mapName[64];
    GetCurrentMap(mapName, sizeof(mapName));

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i)) 
            continue;

        char playerName[64];
        GetClientName(i, playerName, sizeof(playerName));

        // Determinar el equipo del jugador
        int team = GetClientTeam(i);

        if (team == 2)  // Equipo Supervivientes
        {
            if (strlen(survivorNames) > 0)
            {
                StrCat(survivorNames, sizeof(survivorNames), "\x01, "); // Separador con color blanco
            }
            StrCat(survivorNames, sizeof(survivorNames), "\x03");       // Color del equipo
            StrCat(survivorNames, sizeof(survivorNames), playerName);  // Nombre del jugador
        }
        else if (team == 3)  // Equipo Infectados
        {
            if (strlen(infectedNames) > 0)
            {
                StrCat(infectedNames, sizeof(infectedNames), "\x01, "); // Separador con color blanco
            }
            StrCat(infectedNames, sizeof(infectedNames), "\x03");       // Color del equipo
            StrCat(infectedNames, sizeof(infectedNames), playerName);  // Nombre del jugador
        }
    }

    // Imprimir los equipos y el mapa en el chat
    CPrintToChatAll("{green}> {olive}Mapa{default}: {green}%s", mapName);
    CPrintToChatAll("{green}> {olive}Supervivientes{default}: %s", survivorNames);
    CPrintToChatAll("{green}> {olive}Infectados{default}: %s", infectedNames);
}
