using Orleans.Runtime;
using Orleans.Samples.UrlShortener.Web.Models;

namespace Orleans.Samples.UrlShortener.Web.Grains;

public interface IUrlShortenerGrain : IGrainWithStringKey
{
    Task SetUrl(string fullUrl);

    Task<string> GetUrl();
}

public sealed class UrlShortenerGrain(
    [PersistentState(
        stateName: "url",
        storageName: "urls")]
        IPersistentState<UrlDetails> state)
    : Grain, IUrlShortenerGrain
{
    public async Task SetUrl(string fullUrl)
    {
        state.State = new()
        {
            ShortenedRouteSegment = this.GetPrimaryKeyString(),
            FullUrl = fullUrl
        };

        await state.WriteStateAsync();
    }

    public Task<string> GetUrl() =>
        Task.FromResult(state.State.FullUrl);
}