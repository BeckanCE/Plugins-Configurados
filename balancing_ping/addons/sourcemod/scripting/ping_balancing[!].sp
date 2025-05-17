#pragma semicolon 1
#include <sourcemod>
#include <clientprefs>
#include <custom_fakelag>
#include <sdktools>
#include <colors>

#define TEAM_SPECTATOR 1
#define TEAM_SURVIVOR  2
#define TEAM_INFECTED  3
#define MAX_PLAYERS    64

public Plugin:myinfo = 
{
    name = "Ping Balancing",
    author = "Beckham",
    description = "Balances (equalizes) player pings if the difference is greater than 10 ms",
    version = "1.1",
    url = ""
};

int g_survivorClients[MAX_PLAYERS];
float g_survivorPings[MAX_PLAYERS];
int g_survivorCount = 0;

int g_infectedClients[MAX_PLAYERS];
float g_infectedPings[MAX_PLAYERS];
int g_infectedCount = 0;

float g_originalPings[MAX_PLAYERS * 2];
int g_originalPingClients[MAX_PLAYERS * 2];
int g_originalCount = 0;

public void OnPluginStart()
{
    RegConsoleCmd("sm_ecualizeping", Cmd_EqualizePing, "Equalize ping between teams");
    RegConsoleCmd("sm_clearfakelag", Cmd_ClearFakeLag, "Remove fake lag from all players");

    ServerCommand("alias ecualizeping sm_ecualizeping");
    ServerCommand("alias clearfakelag sm_clearfakelag");
}

public Action Cmd_EqualizePing(int client, int args)
{
    g_survivorCount = 0;
    g_infectedCount = 0;
    g_originalCount = 0;

    int maxClients = MaxClients;
    for (int i = 1; i <= maxClients; i++)
    {
        if (!IsClientInGame(i)) continue;
        if (IsFakeClient(i)) continue;

        int team = GetClientTeam(i);
        if (team == TEAM_SPECTATOR) continue;
        if (team != TEAM_SURVIVOR && team != TEAM_INFECTED) continue;

        float latency = GetClientAvgLatency(i, NetFlow_Both) * 1000.0;

        if (team == TEAM_SURVIVOR)
        {
            g_survivorPings[g_survivorCount] = latency;
            g_survivorClients[g_survivorCount] = i;
            g_survivorCount++;
        }
        else if (team == TEAM_INFECTED)
        {
            g_infectedPings[g_infectedCount] = latency;
            g_infectedClients[g_infectedCount] = i;
            g_infectedCount++;
        }
    }

    if (g_survivorCount == 0 || g_infectedCount == 0)
    {
        CPrintToChat(client, "[{green}Ping Balancing{default}] No hay suficientes jugadores en ambos equipos.");
        return Plugin_Handled;
    }

    float globalMinPing = 999999.0;
    float globalMaxPing = -1.0;

    for (int i = 0; i < g_survivorCount; i++)
    {
        if (g_survivorPings[i] < globalMinPing) globalMinPing = g_survivorPings[i];
        if (g_survivorPings[i] > globalMaxPing) globalMaxPing = g_survivorPings[i];
    }
    for (int i = 0; i < g_infectedCount; i++)
    {
        if (g_infectedPings[i] < globalMinPing) globalMinPing = g_infectedPings[i];
        if (g_infectedPings[i] > globalMaxPing) globalMaxPing = g_infectedPings[i];
    }

    float diffPing = globalMaxPing - globalMinPing;

    if (diffPing <= 10.0)
    {
        CPrintToChatAll("[{green}Ping Balancing{default}] La diferencia de ping es menor a {olive}10ms, no se puede aplicar.");
        return Plugin_Handled;
    }

    int minCount = (g_survivorCount < g_infectedCount) ? g_survivorCount : g_infectedCount;

    SortPlayersByPing(minCount);

    CPrintToChatAll("[{green}Ping Balancing{default}] El balance de ping fue aprobado, iniciando....");

    g_originalCount = minCount * 2;
    for (int i = 0; i < minCount; i++)
    {
        g_originalPingClients[i] = g_survivorClients[i];
        g_originalPings[i] = g_survivorPings[i];

        g_originalPingClients[i + minCount] = g_infectedClients[i];
        g_originalPings[i + minCount] = g_infectedPings[i];
    }

    for (int i = 0; i < minCount; i++)
    {
        int survClient = g_survivorClients[i];
        float survOriginalPing = g_survivorPings[i];
        float infectedPing = g_infectedPings[i];

        int infectClient = g_infectedClients[i];
        float infectOriginalPing = g_infectedPings[i];
        float survivorPing = g_survivorPings[i];

        CFakeLag_SetPlayerLatency(survClient, infectedPing);
        CFakeLag_SetPlayerLatency(infectClient, survivorPing);

        char survName[64];
        GetClientName(survClient, survName, sizeof(survName));

        char infectName[64];
        GetClientName(infectClient, infectName, sizeof(infectName));

        if (infectedPing > survOriginalPing)
        {
            CPrintToChatAll("[{green}!{default}] {blue}%s {default}[{olive}%.0f ms {green}-> {olive}%.0f ms{default}]", survName, survOriginalPing, infectedPing);
        }
        else
        {
            CPrintToChatAll("[{green}!{default}] {blue}%s {default}[{olive}%.0f ms {green}-> {olive}%.0f ms{default}]", survName, survOriginalPing, survOriginalPing);
        }

        if (survivorPing > infectOriginalPing)
        {
            CPrintToChatAll("[{green}!{default}] {red}%s {default}[{olive}%.0f ms {green}-> {olive}%.0f ms{default}]", infectName, infectOriginalPing, survivorPing);
        }
        else
        {
            CPrintToChatAll("[{green}!{default}] {red}%s {default}[{olive}%.0f ms {green}-> {olive}%.0f ms{default}]", infectName, infectOriginalPing, infectOriginalPing);
        }
    }

    return Plugin_Handled;
}

public void SortPlayersByPing(int count)
{
    for (int i = 0; i < count - 1; i++)
    {
        for (int j = 0; j < count - 1 - i; j++)
        {
            if (g_survivorPings[j] > g_survivorPings[j + 1])
            {
                float tmpPing = g_survivorPings[j];
                g_survivorPings[j] = g_survivorPings[j + 1];
                g_survivorPings[j + 1] = tmpPing;

                int tmpClient = g_survivorClients[j];
                g_survivorClients[j] = g_survivorClients[j + 1];
                g_survivorClients[j + 1] = tmpClient;
            }

            if (g_infectedPings[j] > g_infectedPings[j + 1])
            {
                float tmpPing = g_infectedPings[j];
                g_infectedPings[j] = g_infectedPings[j + 1];
                g_infectedPings[j + 1] = tmpPing;

                int tmpClient = g_infectedClients[j];
                g_infectedClients[j] = g_infectedClients[j + 1];
                g_infectedClients[j + 1] = tmpClient;
            }
        }
    }
}

public Action Cmd_ClearFakeLag(int client, int args)
{
    CPrintToChatAll("[{green}Ping Balancing{default}] Restableciendo pings....");

    int maxClients = MaxClients;

    for (int i = 1; i <= maxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            int team = GetClientTeam(i);

            char playerName[64];
            GetClientName(i, playerName, sizeof(playerName));

            float originalPing = 0.0;
            bool foundOriginal = false;

            for (int j = 0; j < g_originalCount; j++)
            {
                if (g_originalPingClients[j] == i)
                {
                    originalPing = g_originalPings[j];
                    foundOriginal = true;
                    break;
                }
            }

            CFakeLag_SetPlayerLatency(i, 0.0);

            if (foundOriginal)
            {
                if (team == TEAM_SURVIVOR)
                {
                    CPrintToChatAll("[{green}!{default}] {blue}%s {default}[{olive}%.0f ms {green}-> {olive}%.0f ms{default}]", playerName, originalPing, originalPing);
                }
                else if (team == TEAM_INFECTED)
                {
                    CPrintToChatAll("[{green}!{default}] {red}%s {default}[{olive}%.0f ms {green}-> {olive}%.0f ms{default}]", playerName, originalPing, originalPing);
                }
                else
                {
                    CPrintToChatAll("[{green}!{default}] {green}%s {default}[{olive}%.0f ms {green}-> {olive}%.0f ms{default}]", playerName, originalPing, originalPing);
                }
            }
            else
            {
                float currentPing = GetClientAvgLatency(i, NetFlow_Both) * 1000.0;
                if (team == TEAM_SURVIVOR)
                {
                    CPrintToChatAll("[{green}!{default}] {blue}%s {default}[{olive}%.0f ms{default}]", playerName, currentPing);
                }
                else if (team == TEAM_INFECTED)
                {
                    CPrintToChatAll("[{green}!{default}] {red}%s {default}[{olive}%.0f ms{default}]", playerName, currentPing);
                }
                else
                {
                    CPrintToChatAll("[{green}!{default}] {green}%s {default}[{olive}%.0f ms{default}]", playerName, currentPing);
                }
            }
        }
    }

    return Plugin_Handled;
}
