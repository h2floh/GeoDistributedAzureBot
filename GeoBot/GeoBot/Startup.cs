// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.
//
// Generated with Bot Builder V4 SDK Template for Visual Studio CoreBot v4.6.2

using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Bot.Builder;
using Microsoft.Bot.Builder.Azure;
using Microsoft.Bot.Builder.Integration.AspNet.Core;
using Microsoft.Extensions.DependencyInjection;

using GeoBot.Bots;
using GeoBot.Dialogs;
using Microsoft.Extensions.Logging;
using System.Configuration;
using Microsoft.Extensions.Configuration;

namespace GeoBot
{
    public class Startup
    {

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services, ILogger logger, IConfiguration configuration)
        {
            services.AddMvc().SetCompatibilityVersion(CompatibilityVersion.Version_2_2);
            
            // Create the Bot Framework Adapter with error handling enabled.
            services.AddSingleton<IBotFrameworkHttpAdapter, AdapterWithErrorHandler>();

            // Create the storage we'll be using for User and Conversation state. (Memory is great for testing purposes.)
            IStorage storage;

            /* COSMOSDB STORAGE - Uncomment the code in this section to use CosmosDB storage */
            var cosmosDBIsConfigured = !string.IsNullOrEmpty(configuration["CosmosDBStateStoreEndpoint"]) && !string.IsNullOrEmpty(configuration["CosmosDBStateStoreKey"]) && !string.IsNullOrEmpty(configuration["CosmosDBStateStoreDatabaseId"]) && !string.IsNullOrEmpty(configuration["CosmosDBStateStoreCollectionId"]);
            if (cosmosDBIsConfigured)
            {
                var cosmosDbStorageOptions = new CosmosDbPartitionedStorageOptions()
                {
                    CosmosDbEndpoint = configuration["CosmosDBStateStoreEndpoint"],
                    AuthKey = configuration["CosmosDBStateStoreKey"],
                    DatabaseId = configuration["CosmosDBStateStoreDatabaseId"],
                    ContainerId = configuration["CosmosDBStateStoreCollectionId"]
                };
                storage = new CosmosDbPartitionedStorage(cosmosDbStorageOptions);
            }
            else
            {
                storage = new MemoryStorage();
                logger.LogWarning("CosmosDB Storage not used!");
            } 

            /* END COSMOSDB STORAGE */

            // Create the User state passing in the storage layer.
            var userState = new UserState(storage);
            services.AddSingleton(userState);

            // Create the Conversation state. (Used by the Dialog system itself.)
            services.AddSingleton<ConversationState>();

            // Register LUIS recognizer
            services.AddSingleton<AddressRecognizer>();

            // The MainDialog that will be run by the bot.
            services.AddSingleton<MainDialog>();

            // Create the bot as a transient. In this case the ASP Controller is expecting an IBot.
            services.AddTransient<IBot, DialogAndWelcomeBot<MainDialog>>();
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IHostingEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }
            else
            {
                app.UseHsts();
            }

            app.UseDefaultFiles();
            app.UseStaticFiles();
            app.UseWebSockets();
            app.UseMvc();
        }
    }
}
