#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
    name = "L4D2 Forzar Contenido Personalizado",
    author = "Beckham CE",
    description = "Expulsa a jugadores que no tengan habilitado el contenido personalizado.",
    version = "1.0"
};

public void OnClientPutInServer(int client)
{
    if (!IsFakeClient(client))
    {
        QueryClientConVar(client, "cl_downloadfilter", QueryCallback_CheckFilter);
    }
}

public void QueryCallback_CheckFilter(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
    if (result == ConVarQuery_Okay && IsClientInGame(client))
    {
        if (!StrEqual(cvarValue, "all", false))
        {
            KickClient(client, "Por favor, para poder jugar permite el contenido personalizado. \n[Opciones -> Multijugador -> Contenido de servidor personalizado: Permitir todo]");
        }
    }
}