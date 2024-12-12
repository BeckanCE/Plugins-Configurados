#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <readyup>
#include <colors>

#define PLUGIN_VERSION "1.5"

public Plugin myinfo = 
{
    name = "[L4D2] Team Info on Ready-Up to Live",
    author = "Beckan",
    description = "Prints Survivor and Infected team members, map info, and lists Spectators/Casters when transitioning from Ready-Up to Live.",
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

        // Filtrar jugadores con los prefijos "(S)", "(S) ", "(C)", "(C) "
        if (strncmp(playerName, "(S) ", 4) == 0 || strncmp(playerName, "(S)", 3) == 0 ||
            strncmp(playerName, "(C) ", 4) == 0 || strncmp(playerName, "(C)", 3) == 0)
        {
            continue; // Saltar al siguiente jugador
        }

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
    CPrintToChatAll("{green}> {olive}Supervivientes{default}: {blue}%s", survivorNames);
    CPrintToChatAll("{green}> {olive}Infectados{default}: {red}%s", infectedNames);

    // Lista de espectadores/casters
    char spectatorsAndCasters[512];
    spectatorsAndCasters[0] = '\0';  // Vaciar la cadena al inicio

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i)) 
            continue;

        char playerName[64];
        GetClientName(i, playerName, sizeof(playerName));

        // Detectar jugadores con los prefijos "(S)", "(S) ", "(C)", "(C) "
        if (strncmp(playerName, "(S) ", 4) == 0 || strncmp(playerName, "(S)", 3) == 0 ||
            strncmp(playerName, "(C) ", 4) == 0 || strncmp(playerName, "(C)", 3) == 0)
        {
            if (strlen(spectatorsAndCasters) > 0)
            {
                StrCat(spectatorsAndCasters, sizeof(spectatorsAndCasters), " \x01- "); // Separador con color blanco
            }
            StrCat(spectatorsAndCasters, sizeof(spectatorsAndCasters), "\x05");       // Color del equipo (igual que otros)
            StrCat(spectatorsAndCasters, sizeof(spectatorsAndCasters), playerName);  // Nombre del jugador
        }
    }

    // Imprimir lista de espectadores/casters si hay alguno
    if (strlen(spectatorsAndCasters) > 0)
    {
        CPrintToChatAll("{green}> {olive}Espectadores{default}: {olive}%s", spectatorsAndCasters);
    }
}
