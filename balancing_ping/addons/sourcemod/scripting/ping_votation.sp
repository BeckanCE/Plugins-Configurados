#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <builtinvotes>
#include <colors>

#define TEAM_SPECTATE 1

Handle g_hVote = null;

public Plugin myinfo = 
{
    name        = "Balancing vote",
    author      = "Beckham",
    description = "Voting to balance and restore pings",
    version     = "1.1",
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

    int players[MAXPLAYERS];
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
    SetBuiltinVoteResultCallback(g_hVote, FakeLagVoteResultHandler);
    DisplayBuiltinVote(g_hVote, players, numPlayers, 20);

    FakeClientCommand(client, "Vote Yes");
    return Plugin_Handled;
}

Action Cmd_StartRestoreVote(int client, int args)
{
    if (!CanStartVote(client))
        return Plugin_Handled;

    int players[MAXPLAYERS];
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

void FakeLagVoteResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
    for (int i = 0; i < num_items; i++)
    {
        if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
        {
            if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_votes / 2))
            {
                DisplayBuiltinVotePass(vote, "La votación fue aprobada, balanceando pings...");
                ServerCommand("sm_ecualizeping");
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
                ServerCommand("sm_clearfakelag");
                return;
            }
        }
    }
    DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}
