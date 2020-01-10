using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;

namespace GeoBot
{
    public class Speech
    {
        protected readonly IConfiguration configuration;
        protected readonly ILogger logger;
        private static readonly HttpClient httpClient = new HttpClient();

        public Speech(IConfiguration configuration, ILogger<Speech> logger)
        {
            this.configuration = configuration;
            this.logger = logger;
        }
        public async Task<string> GetSpeechToken()
        {
            // Check on Speech Endpoint
            var speechKeyKey = "SpeechAPIKey" + configuration["region"];
            var speechHostNameKey = "SpeechAPIHostName" + configuration["region"];
            var speechIsConfigured = !string.IsNullOrEmpty(configuration[speechKeyKey]) && !string.IsNullOrEmpty(configuration[speechHostNameKey]);
            if (speechIsConfigured)
            {
                var hostname = configuration[speechHostNameKey];
                var speechUrl = $"{hostname}/sts/v1.0/issuetoken";
                var speechKey = configuration[speechKeyKey];

                using (var client = new HttpClient())
                {
                    client.DefaultRequestHeaders.Add("Ocp-Apim-Subscription-Key", speechKey);
                    UriBuilder uriBuilder = new UriBuilder(speechUrl);

                    var result = await client.PostAsync(uriBuilder.Uri.AbsoluteUri, null);
                    return await result.Content.ReadAsStringAsync();
                }
            }
            else
            {
                // In Case Speech is not configured - skip healthcheck
                return null;
            }
        }
        public string GetSpeechRegion()
        {
            var speechKeyKey = "SpeechAPIKey" + configuration["region"];
            var speechHostNameKey = "SpeechAPIHostName" + configuration["region"];
            var speechIsConfigured = !string.IsNullOrEmpty(configuration[speechKeyKey]) && !string.IsNullOrEmpty(configuration[speechHostNameKey]);
            if (speechIsConfigured)
            {
                return configuration["region"];
            }
            else
            {
                // In Case Speech is not configured - skip healthcheck
                return null;
            }
        }
    }
}
