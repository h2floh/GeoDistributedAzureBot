using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;

namespace GeoBot
{
    public class Directline
    {
        protected readonly IConfiguration configuration;
        protected readonly ILogger logger;
        private static readonly HttpClient httpClient = new HttpClient();

        public Directline(IConfiguration configuration, ILogger<Directline> logger)
        {
            this.configuration = configuration;
            this.logger = logger;
        }

        public async Task<string> GetDirectlineToken()
        {
            // Check on Speech Endpoint
            var directlineIsConfigured = !string.IsNullOrEmpty(configuration["DirectlineKey"]);
            if (directlineIsConfigured)
            {
                var directlineKey = configuration["DirectlineKey"];
                var directlineUrl = $"https://directline.botframework.com/v3/directline/tokens/generate";

                using (var client = new HttpClient())
                {
                    HttpRequestMessage request = new HttpRequestMessage(HttpMethod.Post, directlineUrl);
                    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", directlineKey);
                    var userId = $"dl_{Guid.NewGuid()}";

                    request.Content = new StringContent(
                        JsonConvert.SerializeObject(
                            new { User = new { Id = userId } }),
                            Encoding.UTF8,
                            "application/json");

                    var result = await client.SendAsync(request);
                    string token = String.Empty;

                    if (result.IsSuccessStatusCode)
                    {
                        var body = await result.Content.ReadAsStringAsync();
                        token = JsonConvert.DeserializeObject<DirectLineToken>(body).token;

                        return token;
                    }
                    else
                    {
                        return "There is something wrong when issue the directline token";
                    }
                }
            }
            else
            {
                // In Case Directline is not configured
                return null;
            }
        }
    }
}
