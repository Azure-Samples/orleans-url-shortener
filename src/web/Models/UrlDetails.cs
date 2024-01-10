namespace Orleans.Samples.UrlShortener.Web.Models;

[GenerateSerializer, Alias(nameof(UrlDetails))]
public sealed record class UrlDetails
{
    [Id(0)]
    public string FullUrl { get; set; } = String.Empty;

    [Id(1)]
    public string ShortenedRouteSegment { get; set; } = String.Empty;
}