#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <colors>
#include <readyup>

/*****************************************************************
			G L O B A L   V A R S
*****************************************************************/

ConVar
    g_cvarEnable; // Para habilitar o deshabilitar el plugin.

bool g_bReadyUpAvailable; // Para verificar si Ready Up está disponible.

/*****************************************************************
			P L U G I N   I N F O
*****************************************************************/

public Plugin myinfo = 
{
    name        = "[L4D2] Map on ReadyUp",
    author      = "Beckan",
    description = "Displays the map name in the ReadyUp panel footer.",
    version     = "1.0.1",
    url         = ""
};

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErr_max)
{
    // Se carga el plugin independientemente de si se carga tarde o temprano.
    return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
    // Verificamos si el plugin Ready Up está disponible.
    g_bReadyUpAvailable = LibraryExists("readyup");
}

public void OnLibraryAdded(const char[] sName)
{
    if (StrEqual(sName, "readyup"))
        g_bReadyUpAvailable = true;
}

public void OnLibraryRemoved(const char[] sName)
{
    if (StrEqual(sName, "readyup"))
        g_bReadyUpAvailable = false;
}

/*****************************************************************
			P L U G I N   I N I T I A L I Z A T I O N
*****************************************************************/

public void OnPluginStart()
{
    // Crea el cvar para habilitar/deshabilitar el plugin.
    g_cvarEnable = CreateConVar(
        "sm_mapname_readyup_enable",
        "1",
        "Enable or disable the Map Name on ReadyUp plugin.",
        FCVAR_NOTIFY,
        true, 0.0, true, 1.0
    );

    // Cargar archivo de traducciones.
    LoadTranslations("MapNameReadyUp.phrases");

    AutoExecConfig(false, "MapNameReadyUp");
}

/*****************************************************************
		R E A D Y U P   F O R W A R D S
*****************************************************************/

public OnReadyUpInitiate()
{
    // Verificamos si el plugin está habilitado y si ReadyUp está disponible.
    if (!g_cvarEnable.BoolValue || !g_bReadyUpAvailable)
        return;

    // Obtenemos el nombre del mapa actual.
    char sMapName[64];
    GetCurrentMap(sMapName, sizeof(sMapName));

    // Creamos el mensaje del footer con el nombre del mapa.
    char sFooter[128];
    Format(sFooter, sizeof(sFooter), "%T: %s", "Current Map", LANG_SERVER, sMapName);

    // Añadimos el mensaje al footer del ReadyUp panel.
    AddStringToReadyFooter("");
    AddStringToReadyFooter(sFooter);
}
