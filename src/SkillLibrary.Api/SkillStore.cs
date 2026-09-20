using System.Text.Json;

public sealed class SkillStore(IWebHostEnvironment environment)
{
    private readonly SemaphoreSlim gate = new(1, 1);
    private readonly string catalogPath = Path.Combine(environment.ContentRootPath, "catalog.json");
    private readonly string historyPath = Path.Combine(environment.ContentRootPath, "history");
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web) { WriteIndented = true };

    public async Task<IReadOnlyList<SkillRecord>> ListAsync()
    {
        await gate.WaitAsync();
        try
        {
            return await ReadUnsafeAsync();
        }
        finally
        {
            gate.Release();
        }
    }

    public async Task<SkillRecord?> GetAsync(string id) =>
        (await ListAsync()).FirstOrDefault(skill => skill.Id.Equals(id, StringComparison.OrdinalIgnoreCase));

    public async Task<SkillRecord> SaveDraftAsync(string id, SkillDraft draft, string author)
    {
        return await MutateAsync(id, skill => skill with
        {
            Description = draft.Description,
            Instructions = draft.Instructions,
            Tags = draft.Tags,
            State = "draft",
            UpdatedBy = author,
            UpdatedAt = DateTimeOffset.UtcNow
        });
    }

    public async Task<SkillRecord> PublishAsync(string id, string author)
    {
        var published = await MutateAsync(id, skill => skill with
        {
            Version = Increment(skill.Version),
            State = "published",
            UpdatedBy = author,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        Directory.CreateDirectory(Path.Combine(historyPath, id));
        var snapshot = Path.Combine(historyPath, id, $"{published.Version}.json");
        await File.WriteAllTextAsync(snapshot, JsonSerializer.Serialize(published, JsonOptions));
        return published;
    }

    private async Task<SkillRecord> MutateAsync(string id, Func<SkillRecord, SkillRecord> update)
    {
        await gate.WaitAsync();
        try
        {
            var catalog = await ReadUnsafeAsync();
            var index = catalog.FindIndex(skill => skill.Id.Equals(id, StringComparison.OrdinalIgnoreCase));
            if (index < 0)
            {
                throw new KeyNotFoundException(id);
            }

            catalog[index] = update(catalog[index]);
            await File.WriteAllTextAsync(catalogPath, JsonSerializer.Serialize(catalog, JsonOptions));
            return catalog[index];
        }
        finally
        {
            gate.Release();
        }
    }

    private async Task<List<SkillRecord>> ReadUnsafeAsync()
    {
        if (!File.Exists(catalogPath))
        {
            return [];
        }

        await using var stream = File.OpenRead(catalogPath);
        return await JsonSerializer.DeserializeAsync<List<SkillRecord>>(stream, JsonOptions) ?? [];
    }

    private static string Increment(string version) =>
        int.TryParse(version, out var current) ? (current + 1).ToString() : "1";
}