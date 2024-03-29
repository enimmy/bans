#if defined _sdbbans_included_
	#endinput
#endif
#define _sdbbans_included_


public SharedPlugin __pl_bhopgetstats =
{
    name = "sdbbans",
    file = "sdbbans.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

native bool SDB_IsBanned(int client);

#if !defined REQUIRE_PLUGIN
public void __pl_shavit_core_SetNTVOptional()
{
    MarkNativeAsOptional("SDB_IsBanned");
}
#endif