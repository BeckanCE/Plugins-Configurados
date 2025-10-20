#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <readyup>

#define PLUGIN_VERSION "9.1"

public Plugin myinfo =
{
    name = "[L4D2] Musica navideña en Ready-Up)",
    author = "Beckham CE",
    description = "Descarga y reproduce música navideña durante Ready-Up",
    version = PLUGIN_VERSION,
    url = ""
};

ArrayList g_MasterPathList, g_MasterDurationList;
ArrayList g_CyclePathList, g_CycleDurationList;
char g_sListPath[PLATFORM_MAX_PATH];

char g_sMusicRound1[PLATFORM_MAX_PATH], g_sMusicRound2[PLATFORM_MAX_PATH];
int g_iDurationRound1, g_iDurationRound2;

char g_sCurrentMusic[PLATFORM_MAX_PATH];
int g_iCurrentMusicDuration;
int g_iReadyUpCount = 0;
bool g_bFirstRoundCompleted = false;

ConVar g_hCvarVolume;
bool g_bIsReadyUpActive = false;
Handle g_hDelayedStartTimer = null;
Handle g_hReplayTimer = null;

public void OnPluginStart()
{
    LoadTranslations("common.phrases");
    g_hCvarVolume = CreateConVar("l4d_readyup_music_volume", "1.0", "Volumen de la música (máximo 1.0).", FCVAR_NOTIFY, true, 0.1, true, 1.0);
    RegAdminCmd("sm_readymusic", Cmd_ReadyMusic, ADMFLAG_CONFIG, "Manage ReadyUp music. <stop|replay>");

    g_MasterPathList = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
    g_MasterDurationList = new ArrayList();
    g_CyclePathList = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
    g_CycleDurationList = new ArrayList();

    BuildPath(Path_SM, g_sListPath, sizeof(g_sListPath), "data/music_readyup.txt");
}

public void OnConfigsExecuted() { LoadMasterListFromFile(); }

public void OnMapStart()
{
    g_iReadyUpCount = 0;
    g_bFirstRoundCompleted = false;
    SelectAndPrecacheSongsForMap();
}

public void OnReadyUpInitiate()
{
    g_bIsReadyUpActive = true;
    g_iReadyUpCount++;

    float delay = (!g_bFirstRoundCompleted) ? 35.0 : 5.0;

    g_sCurrentMusic[0] = '\0';

    PrintToServer("[Music Plugin] Round %d. Using reliable delay of %.1f seconds.", g_iReadyUpCount, delay);
    g_hDelayedStartTimer = CreateTimer(delay, Timer_DelayedStartMusic);
}

public void OnRoundIsLive()
{
    g_bIsReadyUpActive = false;
    KillAllMusicTimers();
    if (g_sCurrentMusic[0] != '\0') {
        StopCurrentSongForAll();
        g_sCurrentMusic[0] = '\0';
    }
    g_bFirstRoundCompleted = true;
}

public Action Timer_DelayedStartMusic(Handle timer)
{
    g_hDelayedStartTimer = null;
    if (!g_bIsReadyUpActive) return Plugin_Stop;

    if (g_iReadyUpCount == 1) {
        strcopy(g_sCurrentMusic, sizeof(g_sCurrentMusic), g_sMusicRound1);
        g_iCurrentMusicDuration = g_iDurationRound1;
    } else {
        strcopy(g_sCurrentMusic, sizeof(g_sCurrentMusic), g_sMusicRound2);
        g_iCurrentMusicDuration = g_iDurationRound2;
    }
    
    if (g_sCurrentMusic[0] == '\0') {
        PrintToServer("[Music Plugin] Timer finished, but no song is assigned to play for round %d.", g_iReadyUpCount);
        return Plugin_Stop;
    }

    PrintToServer("[Music Plugin] Timer finished. Double-checked and now playing '%s'", g_sCurrentMusic);
    PlayCurrentSongForAll();
    return Plugin_Stop;
}

public Action Timer_ReplayMusic(Handle timer)
{
    g_hReplayTimer = null;
    if (g_bIsReadyUpActive) PlayCurrentSongForAll();
    return Plugin_Stop;
}

void KillAllMusicTimers()
{
    if (g_hDelayedStartTimer != null) KillTimer(g_hDelayedStartTimer);
    if (g_hReplayTimer != null) KillTimer(g_hReplayTimer);
    g_hDelayedStartTimer = null;
    g_hReplayTimer = null;
}

public Action Cmd_ReadyMusic(int client, int args)
{
    if (!g_bIsReadyUpActive) {
        CReplyToCommand(client, "{green}[{red}Música{green}] {default}Los comandos solo funcionan durante el periodo de {green}Ready-Up.");
        return Plugin_Handled;
    }
    if (args < 1) {
        CReplyToCommand(client, "{green}Uso: {blue}sm_readymusic {default}<stop|replay>");
        return Plugin_Handled;
    }
    char sArg[32]; GetCmdArg(1, sArg, sizeof(sArg));
    if (StrEqual(sArg, "stop", false)) {
        KillAllMusicTimers();
        CPrintToChatAll("{green}>>> {blue}La música se ha detenido.");
        StopCurrentSongForAll();
        g_sCurrentMusic[0] = '\0';
    } else if (StrEqual(sArg, "replay", false)) {
        KillAllMusicTimers();
        if (g_sCurrentMusic[0] == '\0') {
            CReplyToCommand(client, "{green}[{red}Música{green}] {default}No hay ninguna canción sonando para reiniciar.");
            return Plugin_Handled;
        }
        CPrintToChatAll("{green}>>> {blue}La canción se ha reiniciado.");
        StopCurrentSongForAll();
        PlayCurrentSongForAll();
    } else {
        CReplyToCommand(client, "{green}Comando inválido. Uso: {blue}sm_readymusic {default}<stop|replay>");
    }
    return Plugin_Handled;
}

void SelectAndPrecacheSongsForMap()
{
    g_sMusicRound1[0] = '\0'; g_sMusicRound2[0] = '\0';

    if (g_CyclePathList.Length < 2) {
        PrintToServer("[Music Plugin] Playlist cycle exhausted. Starting a new cycle.");
        g_CyclePathList.Clear(); g_CycleDurationList.Clear();
        char sPath[PLATFORM_MAX_PATH];
        for (int i = 0; i < g_MasterPathList.Length; i++) {
            g_MasterPathList.GetString(i, sPath, sizeof(sPath));
            g_CyclePathList.PushString(sPath);
            g_CycleDurationList.Push(g_MasterDurationList.Get(i));
        }
    }

    if (g_CyclePathList.Length == 0) {
        LogError("[Music Plugin] Master playlist is empty. Cannot select music.");
        return;
    }

    int index1 = GetRandomInt(0, g_CyclePathList.Length - 1);
    g_CyclePathList.GetString(index1, g_sMusicRound1, sizeof(g_sMusicRound1));
    g_iDurationRound1 = g_CycleDurationList.Get(index1);
    PrecacheSingleSong(g_sMusicRound1);
    g_CyclePathList.Erase(index1); g_CycleDurationList.Erase(index1);

    if (g_CyclePathList.Length > 0) {
        int index2 = GetRandomInt(0, g_CyclePathList.Length - 1);
        g_CyclePathList.GetString(index2, g_sMusicRound2, sizeof(g_sMusicRound2));
        g_iDurationRound2 = g_CycleDurationList.Get(index2);
        PrecacheSingleSong(g_sMusicRound2);
        g_CyclePathList.Erase(index2); g_CycleDurationList.Erase(index2);
    } else {
        LogMessage("[Music Plugin] Only one song was left in cycle. Round 2 will have no music.");
    }
    PrintToServer("[Music Plugin] Selected for map: R1='%s', R2='%s'", g_sMusicRound1, g_sMusicRound2);
}

void PrecacheSingleSong(const char[] path)
{
    if (path[0] == '\0') return;
    char sDLPath[PLATFORM_MAX_PATH];
    Format(sDLPath, sizeof(sDLPath), "sound/%s", path);
    AddFileToDownloadsTable(sDLPath);
    PrecacheSound(path, true);
}

void PlayCurrentSongForAll()
{
    if (g_sCurrentMusic[0] == '\0') return;
    char sDisplayName[128];
    GetSongDisplayName(g_sCurrentMusic, sDisplayName, sizeof(sDisplayName));
    CPrintToChatAll("{green}>>> {red}Feliz {olive}Navidad {green}<<<");
    CPrintToChatAll("{green}-> {olive}Escuchando: {lightgreen}%s", sDisplayName);
    float volume = g_hCvarVolume.FloatValue;
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && !IsFakeClient(i)) {
            EmitSoundToClient(i, g_sCurrentMusic, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_GUNFIRE, SND_NOFLAGS, volume);
        }
    }
    if (g_hReplayTimer != null) KillTimer(g_hReplayTimer);
    if (g_iCurrentMusicDuration > 0) g_hReplayTimer = CreateTimer(float(g_iCurrentMusicDuration), Timer_ReplayMusic);
}

void StopCurrentSongForAll()
{
    if (g_sCurrentMusic[0] == '\0') return;
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i)) StopSound(i, SNDCHAN_STATIC, g_sCurrentMusic);
    }
}

void LoadMasterListFromFile()
{
    g_MasterPathList.Clear(); g_MasterDurationList.Clear();
    File hFile = OpenFile(g_sListPath, "r");
    if (hFile == null) {
        LogError("Could not read music file: %s", g_sListPath);
        return;
    }
    char sLine[PLATFORM_MAX_PATH], sBuffer[2][PLATFORM_MAX_PATH];
    while (!hFile.EndOfFile() && hFile.ReadLine(sLine, sizeof(sLine))) {
        TrimString(sLine);
        if (sLine[0] != '/' && sLine[1] != '/') {
            if (ExplodeString(sLine, ",", sBuffer, 2, PLATFORM_MAX_PATH) == 2) {
                TrimString(sBuffer[0]); TrimString(sBuffer[1]);
                g_MasterPathList.PushString(sBuffer[0]);
                g_MasterDurationList.Push(StringToInt(sBuffer[1]));
            } else {
                LogError("[Music Plugin] Skipping invalid line in '%s': %s", g_sListPath, sLine);
            }
        }
    }
    CloseHandle(hFile);
    PrintToServer("[Music Plugin] Master playlist loaded with %d songs.", g_MasterPathList.Length);
}

public void OnClientActive(int client)
{
    if (g_bIsReadyUpActive && g_sCurrentMusic[0] != '\0' && g_hDelayedStartTimer == null && !IsFakeClient(client)) {
        CreateTimer(1.5, Timer_PlayForLateJoiner, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action Timer_PlayForLateJoiner(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client > 0 && IsClientInGame(client)) {
        EmitSoundToClient(client, g_sCurrentMusic, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_GUNFIRE, SND_NOFLAGS, g_hCvarVolume.FloatValue);
    }
    return Plugin_Stop;
}

void GetSongDisplayName(const char[] path, char[] buffer, int maxLen)
{
    strcopy(buffer, maxLen, path);
    int commaPos = FindCharInString(buffer, ',');
    if (commaPos != -1) buffer[commaPos] = '\0';
    int start = FindCharInString(buffer, '/', true) + 1;
    char temp[PLATFORM_MAX_PATH];
    strcopy(temp, sizeof(temp), buffer[start]);
    strcopy(buffer, maxLen, temp);
    int end = FindCharInString(buffer, '.');
    if (end != -1) buffer[end] = '\0';
    ReplaceString(buffer, maxLen, "_", " ");
}