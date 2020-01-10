using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Security.Policy;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace GeoBot
{
    public class Healthcheck
    {
        protected readonly IConfiguration configuration;
        protected readonly ILogger logger;
        private static readonly HttpClient httpClient = new HttpClient();

        public Healthcheck(IConfiguration configuration, ILogger<Healthcheck> logger)
        {
            this.configuration = configuration;
            this.logger = logger;
        }

        public async Task CheckHealthAsync(HttpResponse response)
        {
            // Service Unavailable change to 200 OK if there are no errors
            response.StatusCode = 503;

            // Check LUIS
            var lUISresult = await CheckLUIS();
            response.Headers.Add("LUISInnerStatusCode", lUISresult.StatusCode);
            response.Headers.Add("LUISInnerStatusReason", lUISresult.StatusMessage);
            // Check CosmosDB
            var cosmosDBresult = await CheckCosmosDB();
            response.Headers.Add("CosmosDBInnerStatusCode", cosmosDBresult.StatusCode);
            response.Headers.Add("CosmosDBInnerStatusReason", cosmosDBresult.StatusMessage);
            // Check Speech
            var speechResult = await CheckSpeech();
            response.Headers.Add("SpeechInnerStatusCode", speechResult.StatusCode);
            response.Headers.Add("SpeechInnerStatusReason", speechResult.StatusMessage);

            // Check overall success
            if (lUISresult.Success && cosmosDBresult.Success)
            {
                response.StatusCode = 200;
            }
        }

        private async Task<HealthcheckResult> CheckLUIS()
        {
            // Check on LUIS Endpoint
            var luisKeyKey = "LuisAPIKey" + configuration["region"];
            var luisHostNameKey = "LuisAPIHostName" + configuration["region"];

            var luisIsConfigured = !string.IsNullOrEmpty(configuration["LuisAppId"]) && !string.IsNullOrEmpty(configuration[luisKeyKey]) && !string.IsNullOrEmpty(configuration[luisHostNameKey]);
            if (luisIsConfigured)
            {
                var hostname = configuration[luisHostNameKey];
                var appId = configuration["LuisAppId"];
                var q = "cancel";
                var luisUrl = $"{hostname}/luis/v2.0/apps/{appId}?q={q}";

                var requestMessage = new HttpRequestMessage(HttpMethod.Get, luisUrl);
                requestMessage.Headers.Add("Ocp-Apim-Subscription-Key", configuration[luisKeyKey]);
                var responseMessage = await httpClient.SendAsync(requestMessage);

                return new HealthcheckResult(responseMessage.IsSuccessStatusCode, responseMessage.StatusCode.ToString(), responseMessage.ReasonPhrase);
            }
            else
            {
                // In Case LUIS is not configured - skip healthcheck
                return new HealthcheckResult(true, "200", "LUIS not configured");
            }
        }

        private async Task<HealthcheckResult> CheckCosmosDB()
        {
            // Check CosmosDB Accessability
            var cosmosDBIsConfigured = !string.IsNullOrEmpty(configuration["CosmosDBStateStoreEndpoint"]) && !string.IsNullOrEmpty(configuration["CosmosDBStateStoreKey"]) && !string.IsNullOrEmpty(configuration["CosmosDBStateStoreDatabaseId"]) && !string.IsNullOrEmpty(configuration["CosmosDBStateStoreCollectionId"]);
            if (cosmosDBIsConfigured)
            {

                try
                {
                    // read container - to check if until container level all is working
                    using (CosmosClient client = new CosmosClient(configuration["CosmosDBStateStoreEndpoint"], configuration["CosmosDBStateStoreKey"]))
                    {

                        var container = client.GetContainer(configuration["CosmosDBStateStoreDatabaseId"],
                                                            configuration["CosmosDBStateStoreCollectionId"]);

                        var readContainer = await container.ReadContainerAsync();

                        // Return Success
                        return new HealthcheckResult(true, readContainer.StatusCode.ToString(), "CosmosDB account, database and container accessible");
                    }
                }
                catch (Exception e)
                {
                    // Return failure
                    var statusCode = "503";
                    // Try to extract status code from expeption message: Response status code does not indicate success: 401 
                    try
                    {
                        var rx = new Regex(@"Response status code does not indicate success: (\d{3})");
                        Match match = rx.Match(e.Message);
                        if (match.Success)
                        {
                            statusCode = match.Groups[1].Value;
                        }
                    }
                    catch { }

                    return new HealthcheckResult(false, statusCode, e.Message);
                }

            }
            else
            {
                // In Case CosmosDB as state store is not configured - skip healthcheck
                return new HealthcheckResult(true, "200", "CosmosDB not configured");
            }
        }

        private async Task<HealthcheckResult> CheckSpeech()
        {
            Speech speech = new Speech(configuration, null);
            var speechTokenResult = await speech.GetSpeechToken();
            if (String.IsNullOrEmpty(speechTokenResult))
            {
                return new HealthcheckResult(true, "200", "Speech not configured");
            }
            else
            {
                return new HealthcheckResult(true, "200", "Speech not configured");
            }
        }

        // Data Object
        internal class HealthcheckResult
        {
            internal HealthcheckResult(bool success, string statusCode, string statusMessage)
            {
                Success = success;
                StatusCode = statusCode;
                StatusMessage = WebUtility.UrlEncode(statusMessage);
            }
            internal bool Success { get; }
            internal string StatusCode { get; }
            internal string StatusMessage { get; }
        }
    }
}

public class DirectLineToken
{
    public string conversationId { get; set; }
    public string token { get; set; }
    public int expires_in { get; set; }
}
