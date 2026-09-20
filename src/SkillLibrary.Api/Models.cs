using System.Text.Json;
using System.Text.Json.Serialization;

public enum SkillAction
{
    Read,
    Write,
    Run
}

public sealed record SkillAccess(string[] Read, string[] Write, string[] Run);

public sealed record SkillRecord(
    string Id,
    string Name,
    string Description,
    string Version,
    string State,
    string[] Tags,
    string Instructions,
    SkillAccess Access,
    string[] EnabledUsers,
    string UpdatedBy,
    DateTimeOffset UpdatedAt);

public sealed record SkillDraft(string Description, string Instructions, string[] Tags);
public sealed record SkillRunRequest(Dictionary<string, JsonElement> Inputs);
public sealed record SkillInvocation(
    string SkillId,
    string Version,
    string Instructions,
    Dictionary<string, JsonElement> Inputs,
    string RequestedBy,
    DateTimeOffset RequestedAt);

public sealed record DemoPrincipal(string Name, string ObjectId, HashSet<string> Grants)
{
    public static DemoPrincipal From(HttpContext context, IWebHostEnvironment environment)
    {
        var encoded = context.Request.Headers["X-MS-CLIENT-PRINCIPAL"].FirstOrDefault();
        if (!string.IsNullOrWhiteSpace(encoded))
        {
            var payload = Convert.FromBase64String(encoded);
            var source = JsonSerializer.Deserialize<EasyAuthPrincipal>(payload);
            var claims = source?.Claims ?? [];
            var name = claims.FirstOrDefault(claim => claim.Type.EndsWith("/name"))?.Value
                ?? source?.UserDetails
                ?? "authenticated-user";
            var objectId = claims.FirstOrDefault(claim => claim.Type.EndsWith("/objectidentifier"))?.Value
                ?? source?.UserId
                ?? name;
            var grants = claims
                .Where(claim => claim.Type is "roles" or "groups"
                    || claim.Type.EndsWith("/role")
                    || claim.Type.EndsWith("/groups"))
                .Select(claim => claim.Value)
                .ToHashSet(StringComparer.OrdinalIgnoreCase);
            grants.Add("authenticated-users");
            return new DemoPrincipal(name, objectId, grants);
        }

        if (environment.IsDevelopment())
        {
            var grants = (context.Request.Headers["X-Demo-Grants"].FirstOrDefault()
                ?? "skill-readers,skill-authors,skill-runners")
                .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                .ToHashSet(StringComparer.OrdinalIgnoreCase);
            return new DemoPrincipal("local-demo-user", "local-demo-user", grants);
        }

        return new DemoPrincipal("anonymous", "anonymous", []);
    }
}

public sealed record EasyAuthPrincipal(
    [property: JsonPropertyName("userId")] string? UserId,
    [property: JsonPropertyName("userDetails")] string? UserDetails,
    [property: JsonPropertyName("claims")] EasyAuthClaim[]? Claims);

public sealed record EasyAuthClaim(
    [property: JsonPropertyName("typ")] string Type,
    [property: JsonPropertyName("val")] string Value);