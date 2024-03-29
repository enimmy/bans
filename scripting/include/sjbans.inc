#if defined _sjbans_included_
	#endinput
#endif
#define _sjbans_included_


public SharedPlugin __pl_bhopgetstats =
{
    name = "sjbans",
    file = "sjbans.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

native bool SJ_IsBanned(int client);

#if !defined REQUIRE_PLUGIN
public void __pl_shavit_core_SetNTVOptional()
{
    MarkNativeAsOptional("SJ_IsBanned");
}
#endif