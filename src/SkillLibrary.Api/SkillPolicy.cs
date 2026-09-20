public static class SkillPolicy
{
    public static bool Can(SkillRecord skill, DemoPrincipal principal, SkillAction action)
    {
        if (principal.Name == "anonymous")
        {
            return false;
        }

        if (skill.EnabledUsers.Length > 0
            && !skill.EnabledUsers.Contains(principal.ObjectId, StringComparer.OrdinalIgnoreCase)
            && !skill.EnabledUsers.Contains(principal.Name, StringComparer.OrdinalIgnoreCase))
        {
            return false;
        }

        var required = action switch
        {
            SkillAction.Read => skill.Access.Read,
            SkillAction.Write => skill.Access.Write,
            SkillAction.Run => skill.Access.Run,
            _ => []
        };

        return required.Contains("authenticated-users", StringComparer.OrdinalIgnoreCase)
            || required.Any(principal.Grants.Contains);
    }
}