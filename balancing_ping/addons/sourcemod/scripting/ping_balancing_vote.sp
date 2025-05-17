#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <builtinvotes>
#include <colors>
#include <sdktools>
#include <custom_fakelag>

#define TEAM_SPECTATE 1
#define TEAM_SURVIVOR  2
#define TEAM_INFECTED  3
#define MAX_PLAYERS    64

Handle g_hVote = null;

int g_survivorClients[MAX_PLAYERS];
float g_survivorPings[MAX_PLAYERS];
int g_survivorCount = 0;

int g_infectedClients[MAX_PLAYERS];
float g_infectedPings[MAX_PLAYERS];
int g_infectedCount = 0;

float g_originalPings[MAX_PLAYERS * 2];
int g_originalPingClients[MAX_PLAYERS * 2];
int g_originalCount = 0;

public Plugin myinfo = 
{
    name        = "Ping Balancing Vote",
    author      = "Beckham",
    description = "Allows you to balance (equalize) the pings of survivors and infected",
    version     = "1.2",
    url         = ""
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_ping_balancing", Cmd_StartBalanceVote);
    RegConsoleCmd("sm_no_ping_balancing", Cmd_StartRestoreVote);

    ServerCommand("alias ping_balancing sm_ping_balancing");
    ServerCommand("alias no_ping_balancing sm_no_ping_balancing");
}

Action Cmd_StartBalanceVote(int client, int args)
{
    if (!CanStartVote(client))
        return Plugin_Handled;

    int players[MAX_PLAYERS];
    int numPlayers = GetEligiblePlayers(players);

    if (numPlayers == 0)
    {
        CPrintToChat(client, "{green}No hay jugadores activos para iniciar la votación.");
        return Plugin_Handled;
    }

    char sTitle[64];
    Format(sTitle, sizeof(sTitle), "¿Balancear los pings de los jugadores?");

    g_hVote = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
    SetBuiltinVoteArgument(g_hVote, sTitle);
    SetBuiltinVoteInitiator(g_hVote, client);
    SetBuiltinVoteResultCallback(g_hVote, BalanceVoteResultHandler);
    DisplayBuiltinVote(g_hVote, players, numPlayers, 20);

    FakeClientCommand(client, "Vote Yes");
    return Plugin_Handled;
}

Action Cmd_StartRestoreVote(int client, int args)
{
    if (!CanStartVote(client))
        return Plugin_Handled;

    int players[MAX_PLAYERS];
    int numPlayers = GetEligiblePlayers(players);

    if (numPlayers == 0)
    {
        CPrintToChat(client, "{green}No hay jugadores activos para iniciar la votación.");
        return Plugin_Handled;
    }

    char sTitle[64];
    Format(sTitle, sizeof(sTitle), "¿Restaurar los pings?");

    g_hVote = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
    SetBuiltinVoteArgument(g_hVote, sTitle);
    SetBuiltinVoteInitiator(g_hVote, client);
    SetBuiltinVoteResultCallback(g_hVote, RestoreVoteResultHandler);
    DisplayBuiltinVote(g_hVote, players, numPlayers, 20);

    FakeClientCommand(client, "Vote Yes");
    return Plugin_Handled;
}

bool CanStartVote(int client)
{
    if (client == 0)
    {
        CReplyToCommand(client, "{green}Este comando no puede ejecutarse desde consola.");
        return false;
    }

    if (GetClientTeam(client) <= TEAM_SPECTATE)
    {
        CPrintToChat(client, "{green}Los espectadores no pueden iniciar esta votación.");
        return false;
    }

    if (IsBuiltinVoteInProgress())
    {
        CPrintToChat(client, "{green}Ya hay una votación en progreso. Espera a que termine.");
        return false;
    }

    return true;
}

int GetEligiblePlayers(int[] players)
{
    int count = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > TEAM_SPECTATE)
        {
            players[count++] = i;
        }
    }
    return count;
}

void VoteActionHandler(Handle vote, BuiltinVoteAction action, int param1, int param2)
{
    if (action == BuiltinVoteAction_End)
    {
        CloseHandle(vote);
        g_hVote = null;
    }
    else if (action == BuiltinVoteAction_Cancel)
    {
        DisplayBuiltinVoteFail(vote, view_as<BuiltinVoteFailReason>(param1));
    }
}

void BalanceVoteResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
    for (int i = 0; i < num_items; i++)
    {
        if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
        {
            if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_votes / 2))
            {
                DisplayBuiltinVotePass(vote, "La votación fue aprobada, balanceando pings...");
                ExecutePingBalanceLogic();
                return;
            }
        }
    }
    DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}

void RestoreVoteResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
    for (int i = 0; i < num_items; i++)
    {
        if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
        {
            if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_votes / 2))
            {
                DisplayBuiltinVotePass(vote, "La votación fue aprobada, restaurando pings...");
                ExecuteRestoreLogic();
                return;
            }
        }
    }
    DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}

void ExecutePingBalanceLogic()
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
        if (team == TEAM_SPECTATE) continue;
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
        CPrintToChatAll("[{green}Ping Balancing{default}] No hay suficientes jugadores en ambos equipos.");
        return;
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
        return;
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
}

void ExecuteRestoreLogic()
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
