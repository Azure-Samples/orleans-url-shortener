using Orleans.Samples.UrlShortener.Web.Grains;

var builder = WebApplication.CreateBuilder(args);

builder.Host.UseOrleans(static siloBuilder =>
{
    siloBuilder
        .UseLocalhostClustering()
        .AddMemoryGrainStorage("urls");
});

using var app = builder.Build();

app.MapGet("/", () => Results.File(Path.Combine(builder.Environment.WebRootPath, "index.html"), "text/html"));

app.MapGet("shorten", Shorten);

app.MapGet("/go/{shortenedRouteSegment:required}", Redirect);

await app.RunAsync();

static async Task<IResult> Shorten(IGrainFactory grains, HttpRequest request, string url)
{
    // Gets the base URL for the current request
    var host = $"{request.Scheme}://{request.Host.Value}";

    // Validates the URL query string
    if (string.IsNullOrWhiteSpace(url) && Uri.IsWellFormedUriString(url, UriKind.Absolute) is false)
    {
        return Results.BadRequest($"""
            The URL query string is required and needs to be well formed.
            Consider, ${host}/shorten?url=https://www.microsoft.com.
            """);
    }

    // Create a unique, short ID
    var shortenedRouteSegment = Guid.NewGuid().GetHashCode().ToString("X");

    // Create and persist a grain with the shortened ID and full URL
    var shortenerGrain =
        grains.GetGrain<IUrlShortenerGrain>(shortenedRouteSegment);

    // Sets the URL in the grain
    await shortenerGrain.SetUrl(url);

    // Return the shortened URL for later use
    var resultBuilder = new UriBuilder(host)
    {
        Path = $"/go/{shortenedRouteSegment}"
    };

    // Returns a 200 OK response with the shortened URL in the JSON body
    return Results.Json(new
    {
        original = url,
        shortened = resultBuilder.Uri
    });
}

static async Task<IResult> Redirect(IGrainFactory grains, string shortenedRouteSegment)
{
    // Retrieve the grain using the shortened ID and url to the original URL
    var shortenerGrain = grains.GetGrain<IUrlShortenerGrain>(shortenedRouteSegment);

    // Gets the URL from the grain
    var url = await shortenerGrain.GetUrl();

    // Handles missing schemes, defaults to "http://"
    var redirectBuilder = new UriBuilder(url);

    // Returns a 302 Found response with a redirect to the original URL in the Location header
    return Results.Redirect(
        url: redirectBuilder.Uri.ToString(),
        permanent: false,
        preserveMethod: false
    );
}