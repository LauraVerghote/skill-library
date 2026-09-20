var builder = WebApplication.CreateBuilder(args);
builder.Services.AddSingleton<SkillStore>();
var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();

app.MapGet("/health", () => Results.Ok(new { status = "healthy" }));
app.MapGet("/api/me", (HttpContext context) => Results.Ok(DemoPrincipal.From(context, app.Environment)));

app.MapGet("/api/skills", async (HttpContext context, SkillStore store) =>
{
    var principal = DemoPrincipal.From(context, app.Environment);
    var skills = await store.ListAsync();
    return Results.Ok(skills.Where(skill => SkillPolicy.Can(skill, principal, SkillAction.Read)));
});

app.MapGet("/api/skills/{id}", async (string id, HttpContext context, SkillStore store) =>
{
    var skill = await store.GetAsync(id);
    if (skill is null)
    {
        return Results.NotFound();
    }

    var principal = DemoPrincipal.From(context, app.Environment);
    return SkillPolicy.Can(skill, principal, SkillAction.Read)
        ? Results.Ok(skill)
        : Results.StatusCode(StatusCodes.Status403Forbidden);
});

app.MapPut("/api/skills/{id}/draft", async (string id, SkillDraft draft, HttpContext context, SkillStore store) =>
{
    var skill = await store.GetAsync(id);
    if (skill is null)
    {
        return Results.NotFound();
    }

    var principal = DemoPrincipal.From(context, app.Environment);
    if (!SkillPolicy.Can(skill, principal, SkillAction.Write))
    {
        return Results.StatusCode(StatusCodes.Status403Forbidden);
    }

    return Results.Ok(await store.SaveDraftAsync(id, draft, principal.Name));
});

app.MapPost("/api/skills/{id}/publish", async (string id, HttpContext context, SkillStore store) =>
{
    var skill = await store.GetAsync(id);
    if (skill is null)
    {
        return Results.NotFound();
    }

    var principal = DemoPrincipal.From(context, app.Environment);
    if (!SkillPolicy.Can(skill, principal, SkillAction.Write))
    {
        return Results.StatusCode(StatusCodes.Status403Forbidden);
    }

    return Results.Ok(await store.PublishAsync(id, principal.Name));
});

app.MapPost("/api/skills/{id}/run", async (string id, SkillRunRequest request, HttpContext context, SkillStore store) =>
{
    var skill = await store.GetAsync(id);
    if (skill is null)
    {
        return Results.NotFound();
    }

    var principal = DemoPrincipal.From(context, app.Environment);
    if (!SkillPolicy.Can(skill, principal, SkillAction.Run))
    {
        return Results.StatusCode(StatusCodes.Status403Forbidden);
    }

    if (skill.State != "published")
    {
        return Results.Conflict(new { error = "Only published skills can run." });
    }

    return Results.Ok(new SkillInvocation(
        skill.Id,
        skill.Version,
        skill.Instructions,
        request.Inputs,
        principal.Name,
        DateTimeOffset.UtcNow));
});

app.Run();